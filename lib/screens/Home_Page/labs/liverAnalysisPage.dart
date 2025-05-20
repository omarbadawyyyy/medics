import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as path;
import 'package:lottie/lottie.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class LiverAnalysisPage extends StatefulWidget {
  const LiverAnalysisPage({super.key});

  @override
  _LiverAnalysisPageState createState() => _LiverAnalysisPageState();
}

class _LiverAnalysisPageState extends State<LiverAnalysisPage> with SingleTickerProviderStateMixin {
  List<File> _selectedFiles = [];
  final ImagePicker _imagePicker = ImagePicker();
  String _analysisResult = '';
  bool _isLoading = false;
  bool _isAnalysisRequested = false;
  final String _apiKey = 'AIzaSyBktPI-UXkVe48F647saaMHuby7WoNjz1I'; // Replace with your API key
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _showInitialMessage();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  void _showInitialMessage() {
    setState(() {
      _analysisResult = 'Upload liver reports for analysis.';
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(images.map((image) => File(image.path)).toList());
          _analysisResult = '';
        });
      }
    } catch (e) {
      setState(() {
        _analysisResult = 'Error picking images: $e';
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.files.map((file) => File(file.path!)).toList());
          _analysisResult = '';
        });
      }
    } catch (e) {
      setState(() {
        _analysisResult = 'Error picking files: $e';
      });
    }
  }

  void _clearFiles() {
    setState(() {
      _selectedFiles.clear();
      _showInitialMessage();
    });
  }

  Future<String> _analyzeFiles() async {
    if (_selectedFiles.isEmpty) {
      return 'يرجى رفع ملف واحد على الأقل.';
    }

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey');
      List<Map<String, dynamic>> parts = [];

      parts.add({
        "text": "هذه ملفات (صور أو PDF) لتقارير طبية متعلقة بالكبد. قم بتحليلها كتقرير واحد واتبع التعليمات:\n"
            "1. قدم تشخيصًا عامًا موجزًا بالعربية تحت عنوان 'التشخيص العام:'، مع ذكر أمراض الكبد المحتملة مثل التهاب الكبد (Hepatitis)، تليف الكبد (Cirrhosis)، أو مرض الكبد الدهني بناءً على القيم. مثال: 'التشخيص العام: ارتفاع ALT وAST يشير إلى احتمال التهاب الكبد أو تليف الكبد.' إذا كانت القيم طبيعية، اكتب: 'التشخيص العام: الكبد سليم.'\n"
            "2. تحت عنوان 'القيم غير الطبيعية:'، اذكر فقط القيم الرقمية غير الطبيعية (مثل ALT، AST، البيليروبين، الألبومين) مع وحداتها، دون النطاقات الطبيعية أو أرقام الصفحات. مثال: 'القيم غير الطبيعية:\n- ALT: 60 وحدة/لتر\n- البيليروبين: 2.0 مجم/ديسيلتر'. إذا لم توجد قيم غير طبيعية، اكتب 'لا توجد قيم غير طبيعية.'\n"
            "3. استخدم نبرة طبية موجزة بالعربية، وتجنب أي تفاصيل إضافية."
      });

      for (var file in _selectedFiles) {
        final fileBytes = await file.readAsBytes();
        final base64String = base64Encode(fileBytes);
        parts.add({
          "inlineData": {
            "mimeType": file.path.endsWith('.pdf') ? "application/pdf" : "image/jpeg",
            "data": base64String,
          }
        });
      }

      final requestBody = {
        "contents": [
          {
            "parts": parts,
          }
        ]
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          return 'خطأ: لا توجد بيانات من Gemini.';
        }
      } else {
        return 'خطأ: فشل الاتصال بـ Gemini (كود: ${response.statusCode}).';
      }
    } catch (e) {
      return 'خطأ: $e';
    }
  }

  void _showFilePreview(File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          child: file.path.endsWith('.pdf')
              ? FutureBuilder<bool>(
            future: File(file.path).exists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data == true) {
                return PDFView(
                  filePath: file.path,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: true,
                  pageFling: true,
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error loading PDF: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                );
              }
              return const Center(
                child: Icon(Icons.error, size: 50, color: Colors.red),
              );
            },
          )
              : Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 50, color: Colors.red),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: screenHeight * 0.25,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.blue[900],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Liver Analysis',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.06,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.blue[900]!, Colors.blue[600]!],
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        'assets/images/medical_background.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Help', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        content: Text(
                          '1. Upload liver report images or PDFs.\n'
                              '2. Ensure text is clear.\n'
                              '3. Tap "Analyze" to view results.',
                          style: GoogleFonts.cairo(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK', style: GoogleFonts.cairo()),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        child: Column(
                          children: [
                            Text(
                              'Upload Reports',
                              style: GoogleFonts.cairo(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[900],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            _selectedFiles.isNotEmpty
                                ? Column(
                              children: [
                                SizedBox(
                                  height: screenHeight * 0.25,
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedFiles.length,
                                    itemBuilder: (context, index) {
                                      final file = _selectedFiles[index];
                                      final isImage = file.path.endsWith('.jpg') || file.path.endsWith('.jpeg') || file.path.endsWith('.png');
                                      return GestureDetector(
                                        onTap: () => _showFilePreview(file),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                width: screenWidth * 0.35,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(15),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.withOpacity(0.2),
                                                      spreadRadius: 2,
                                                      blurRadius: 5,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: isImage
                                                    ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(13),
                                                  child: Image.file(
                                                    file,
                                                    fit: BoxFit.cover,
                                                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                                      if (wasSynchronouslyLoaded) return child;
                                                      return AnimatedOpacity(
                                                        opacity: frame == null ? 0 : 1,
                                                        duration: const Duration(milliseconds: 500),
                                                        child: child,
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Center(
                                                        child: Icon(
                                                          Icons.error,
                                                          color: Colors.red,
                                                          size: 50,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                                    : Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(
                                                        Icons.picture_as_pdf,
                                                        size: 50,
                                                        color: Colors.red,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        path.basename(file.path),
                                                        style: GoogleFonts.cairo(
                                                          color: Colors.grey[600],
                                                          fontSize: screenWidth * 0.03,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right: -10,
                                                top: -10,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedFiles.removeAt(index);
                                                      if (_selectedFiles.isEmpty) {
                                                        _showInitialMessage();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.red[600],
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.2),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    padding: const EdgeInsets.all(4),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                TextButton.icon(
                                  onPressed: _clearFiles,
                                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                                  label: Text(
                                    'Clear',
                                    style: GoogleFonts.cairo(color: Colors.red),
                                  ),
                                ),
                              ],
                            )
                                : Container(
                              height: screenHeight * 0.25,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: screenWidth * 0.12,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      'No Files',
                                      style: GoogleFonts.cairo(
                                        color: Colors.grey[600],
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _pickImages,
                              icon: const Icon(Icons.photo_library),
                              label: Text(
                                'Images',
                                style: GoogleFonts.cairo(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.02,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                            ).animate().scale(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _pickFiles,
                              icon: const Icon(Icons.attach_file),
                              label: Text(
                                'Files',
                                style: GoogleFonts.cairo(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.02,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                            ).animate().scale(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    ElevatedButton(
                      onPressed: _isLoading || _isAnalysisRequested
                          ? null
                          : () async {
                        setState(() {
                          _isAnalysisRequested = true;
                          _isLoading = true;
                        });
                        final result = await _analyzeFiles();
                        setState(() {
                          _analysisResult = result;
                          _isLoading = false;
                          _isAnalysisRequested = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Lottie.asset(
                              'assets/animations/loading.json',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Analyzing...',
                            style: GoogleFonts.cairo(),
                          ),
                        ],
                      )
                          : Text(
                        'Analyze',
                        style: GoogleFonts.cairo(fontSize: screenWidth * 0.045),
                      ),
                    ).animate().scale(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    ),
                    if (_analysisResult.isNotEmpty) ...[
                      SizedBox(height: screenHeight * 0.02),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _analysisResult.contains('خطأ') ? Icons.error : Icons.check_circle,
                                    color: _analysisResult.contains('خطأ') ? Colors.red : Colors.green,
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Result',
                                    style: GoogleFonts.cairo(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: RichText(
                                  text: TextSpan(
                                    children: _buildAnalysisText(_analysisResult, screenWidth),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildAnalysisText(String result, double screenWidth) {
    List<TextSpan> spans = [];
    List<String> lines = result.split('\n');

    for (String line in lines) {
      if (line.isEmpty) continue;

      if (line.startsWith('التشخيص العام:')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: GoogleFonts.cairo(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ));
      } else if (line.startsWith('القيم غير الطبيعية:')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: GoogleFonts.cairo(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ));
      } else if (line.contains('خطأ')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: GoogleFonts.cairo(
            fontSize: screenWidth * 0.035,
            color: Colors.red,
          ),
        ));
      } else if (line.startsWith('- ')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: GoogleFonts.cairo(
            fontSize: screenWidth * 0.035,
            color: Colors.red[700],
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: '$line\n',
          style: GoogleFonts.cairo(
            fontSize: screenWidth * 0.035,
            color: Colors.black,
          ),
        ));
      }
    }

    return spans;
  }
}