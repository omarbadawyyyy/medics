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

// Page for analyzing medical reports
class BloodAnalysisPage extends StatefulWidget {
  const BloodAnalysisPage({super.key});

  @override
  _BloodAnalysisPageState createState() => _BloodAnalysisPageState();
}

class _BloodAnalysisPageState extends State<BloodAnalysisPage> with SingleTickerProviderStateMixin {
  List<File> _selectedFiles = []; // To store selected files (images or PDFs)
  final ImagePicker _imagePicker = ImagePicker();
  String _analysisResult = '';
  bool _isLoading = false;
  bool _isAnalysisRequested = false; // To prevent multiple requests
  final String _apiKey = 'AIzaSyBktPI-UXkVe48F647saaMHuby7WoNjz1I'; // Replace with your API key
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _showInitialMessage();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _loadingAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  void _showInitialMessage() {
    setState(() {
      _analysisResult = 'Please upload images or PDF files of medical reports to get a quick summary.';
    });
  }

  // Pick multiple images from the gallery
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
        _analysisResult = 'Error while selecting images: $e';
      });
    }
  }

  // Pick files (images or PDFs) using file picker
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
        _analysisResult = 'Error while selecting files: $e';
      });
    }
  }

  // Clear all selected files
  void _clearFiles() {
    setState(() {
      _selectedFiles.clear();
      _showInitialMessage();
    });
  }

  // Analyze all uploaded files as a single report using Gemini API
  Future<String> _analyzeFiles() async {
    if (_selectedFiles.isEmpty) {
      return 'يرجى رفع ملف واحد على الأقل للتحليل.';
    }

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey');
      List<Map<String, dynamic>> parts = [];

      // Add the text prompt with updated structure, including troponin analysis
      parts.add({
        "text": "هذه ملفات (صور أو PDF) لتقارير طبية. أريد منك تحليل جميع الملفات معًا كتقرير واحد والقيام بما يلي:\n"
            "1. ابدأ الرد ب: 'لقد قمت بمراجعة التقارير الطبية بدقة، وفيما يلي ملخص النتائج:'.\n"
            "2. قدم تشخيصًا عامًا بالعربية تحت عنوان 'التشخيص العام:'، مع التركيز على أمراض القلب إذا تم العثور على قيم مثل التروبونين (Troponin). على سبيل المثال: 'التشخيص العام:\n- ارتفاع مستوى التروبونين قد يشير إلى نوبة قلبية أو التهاب عضلة القلب، يُنصح باستشارة طبيب قلب فورًا.\n- انخفاض الهيموجلوبين قد يشير إلى فقر دم.' إذا كانت جميع القيم ضمن النطاقات الطبيعية، اكتب: 'التشخيص العام:\n- لا توجد مشكلات صحية واضحة بناءً على التقارير، جميع القيم ضمن النطاقات الطبيعية.'\n"
            "3. استخرج فقط القيم الرقمية التي خارج النطاق الطبيعي من جميع الملفات (مثل التروبونين، الهيموجلوبين، السكر في الدم، الكرياتينين، الكوليسترول، أو أي قيم أخرى) مع وحداتها. بالنسبة لكل قيمة، إذا كان الملف PDF، حدد رقم الصفحة بالعربية (مثل 'الصفحة الأولى'، 'الصفحة الثانية'، إلخ) دون ذكر اسم الملف. إذا كان الملف صورة (jpg، jpeg، png)، لا تذكر أي معلومات إضافية. قدم النتائج بالعربية بصيغة موجزة تحت عنوان 'القيم الغير طبيعية:'، مثل: 'القيم الغير طبيعية:\n- التروبونين (الصفحة الأولى): 0.1 نانوغرام/مل (النطاق الطبيعي: أقل من 0.04 نانوغرام/مل) - أعلى من الطبيعي\n- الهيموجلوبين: 11 جم/ديسيلتر (النطاق الطبيعي للنساء: 12.1-15.1 جم/ديسيلتر) - أقل من الطبيعي'. قارن هذه القيم بالنطاقات الطبيعية إذا كانت معروفة (مثل التروبونين أقل من 0.04 نانوغرام/مل؛ الهيموجلوبين للرجال 13.8-17.2 جم/ديسيلتر، للنساء 12.1-15.1 جم/ديسيلتر؛ السكر الصائم 70-99 مجم/ديسيلتر؛ الكرياتينين للرجال 0.7-1.3 مجم/ديسيلتر، للنساء 0.6-1.1 مجم/ديسيلتر؛ TSH 0.4-4.0 ميلي وحدة/لتر؛ الكوليسترول الكلي أقل من 200 مجم/ديسيلتر طبيعي، 200-239 مجم/ديسيلتر مرتفع قليلاً، أعلى من 240 مجم/ديسيلتر مرتفع). إذا لم يكن النطاق الطبيعي معروفًا لقيمة ما، اذكر القيمة فقط دون النطاق.\n"
            "4. إذا لم يتم العثور على قيم رقمية في الملفات، اكتب 'لم أتمكن من العثور على قيم رقمية في التقارير.' بعد التشخيص العام.\n"
            "5. إذا تم العثور على قيم التروبونين، أعط الأولوية لتحليلها واذكر احتمالية وجود مشكلات قلبية مثل النوبة القلبية أو التهاب عضلة القلب بناءً على القيم (على سبيل المثال، إذا كان التروبونين > 0.04 نانوغرام/مل، اذكر أنه مرتفع ويشير إلى ضرر قلبي محتمل).\n"
            "استخدم نبرة احترافية ولكن طبيعية بالعربية، كما لو كان طبيب يكتب، وتأكد أن الرد دقيق وواضح ويجنب التفاصيل غير الضرورية."
      });

      // Add all files as inline data
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
          return 'Error: No data available from Gemini API.';
        }
      } else {
        return 'Error: Failed to get response from Gemini API. Please check the API key or internet connection (status code: ${response.statusCode}).';
      }
    } catch (e) {
      return 'Error during analysis: $e';
    }
  }

  // Show preview of file (image or PDF)
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
        textDirection: TextDirection.rtl, // Ensure RTL for Arabic UI
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
                  'Blood Analysis',
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
                        'assets/images/medical_background.png', // Add a medical-themed background image
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
                        title: Text('Instructions', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        content: Text(
                          '1. Upload clear images or PDF files of medical reports.\n'
                              '2. Ensure the text in the files is readable.\n'
                              '3. Press "Analyze Files" to get a summary of the results.\n'
                              '4. If the reports contain troponin analysis, the focus will be on diagnosing heart diseases.',
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
                              'Upload Your Medical Reports Here',
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
                                    'Clear All',
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
                                      'No Files Selected',
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
                                'Upload Images',
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
                                'Upload Files',
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
                              'assets/animations/loading.json', // Add a Lottie animation file
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
                        'Analyze Files',
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
                                    'Analysis Result',
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
    bool isGeneralDiagnosisSection = false;
    bool isAbnormalValuesSection = false;

    for (String line in lines) {
      if (line.isEmpty) continue;

      if (line.startsWith('لقد قمت بمراجعة التقارير الطبية بدقة، وفيما يلي ملخص النتائج:')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: GoogleFonts.cairo(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ));
      } else if (line.startsWith('التشخيص العام:')) {
        isGeneralDiagnosisSection = true;
        spans.add(TextSpan(
          text: '$line\n',
          style: GoogleFonts.cairo(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ));
      } else if (line.startsWith('القيم الغير طبيعية:')) {
        isGeneralDiagnosisSection = false;
        isAbnormalValuesSection = true;
        spans.add(TextSpan(
          text: '$line\n',
          style: GoogleFonts.cairo(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ));
      } else if (line.contains('أعلى من الطبيعي')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: GoogleFonts.cairo(
            fontSize: screenWidth * 0.035,
            color: Colors.red[700],
          ),
        ));
      } else if (line.contains('أقل من الطبيعي')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: GoogleFonts.cairo(
            fontSize: screenWidth * 0.035,
            color: Colors.blue[700],
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
      } else {
        spans.add(TextSpan(
          text: '$line\n',
          style: GoogleFonts.cairo(
            fontSize: screenWidth * 0.035,
            color: isGeneralDiagnosisSection || isAbnormalValuesSection ? Colors.black87 : Colors.black,
          ),
        ));
      }

      if (isGeneralDiagnosisSection && !line.startsWith('التشخيص العام:') && !line.contains('لا توجد مشكلات صحية واضحة بناءً على التقارير، جميع القيم ضمن النطاقات الطبيعية.')) {
        spans.add(TextSpan(
          text: '\n',
          style: GoogleFonts.cairo(fontSize: screenWidth * 0.035),
        ));
        isGeneralDiagnosisSection = false;
      }

      if (isAbnormalValuesSection && !line.startsWith('القيم الغير طبيعية:') && !line.contains('أعلى من الطبيعي') && !line.contains('أقل من الطبيعي')) {
        spans.add(TextSpan(
          text: '\n',
          style: GoogleFonts.cairo(fontSize: screenWidth * 0.035),
        ));
        isAbnormalValuesSection = false;
      }
    }

    return spans;
  }
}
