import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

// Page for analyzing retinal images
class EyeAnalysisPage extends StatefulWidget {
  const EyeAnalysisPage({super.key});

  @override
  _EyeAnalysisPageState createState() => _EyeAnalysisPageState();
}

class _EyeAnalysisPageState extends State<EyeAnalysisPage> with SingleTickerProviderStateMixin {
  File? _image;
  final ImagePicker _picker = ImagePicker();
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
      _analysisResult = 'This analysis checks for the following eye diseases: Diabetic Retinopathy and Cataracts. Upload a retinal image to start.';
    });
  }

  // Capture an image using the camera
  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _image = File(image.path);
          _analysisResult = '';
        });
      }
    } catch (e) {
      setState(() {
        _analysisResult = 'Error capturing image: $e';
      });
    }
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _image = File(image.path);
          _analysisResult = '';
        });
      }
    } catch (e) {
      setState() {
        _analysisResult = 'Error selecting image: $e';
      };
    }
  }

  // Analyze the image using Gemini API
  Future<String> _analyzeImage() async {
    if (_image == null) {
      return 'Please capture or select an image first';
    }

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey');
      final imageBytes = await _image!.readAsBytes();
      final base64String = base64Encode(imageBytes);

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": "This is a retinal image. Analyze the image and determine if the following diseases are present: Diabetic Retinopathy, Cataracts. Provide the response in English in a concise format, with each disease on a new line (e.g., Diabetic Retinopathy: Positive\nCataracts: Negative). Use 'Positive' if the disease is detected and 'Negative' if not. Do not add extra details."
              },
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64String,
                }
              }
            ]
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
        return 'Error: Failed to get response from Gemini API. Check API key or internet connection (status code: ${response.statusCode}).';
      }
    } catch (e) {
      return 'Analysis error: $e';
    }
  }

  // Show an alert dialog with animation if a disease is detected
  void _showAlertWithAnimation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.red[50],
          title: Text(
            '⚠️ Alert',
            style: GoogleFonts.poppins(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'A potential eye disease has been detected. Please visit an eye doctor immediately.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
        );
      },
    );
  }

  // Show a success message if no disease is detected
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Congratulations! Your eyes are healthy.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: screenHeight * 0.25,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.blue[900],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Eye Analysis',
                style: GoogleFonts.poppins(
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
                      title: Text('Instructions', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      content: Text(
                        '1. Capture or upload a clear retinal image.\n'
                            '2. Ensure the image is clear and readable.\n'
                            '3. Click "Analyze Image" to get results.\n'
                            '4. The analysis checks for Diabetic Retinopathy and Cataracts.',
                        style: GoogleFonts.poppins(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK', style: GoogleFonts.poppins()),
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
                            'Capture or upload a retinal image for analysis',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Container(
                            height: screenHeight * 0.25,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: _image != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.file(
                                _image!,
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
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: screenWidth * 0.12,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    'No image selected',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: screenWidth * 0.04,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_image != null) ...[
                            SizedBox(height: screenHeight * 0.01),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _image = null;
                                  _showInitialMessage();
                                });
                              },
                              icon: const Icon(Icons.delete_sweep, color: Colors.red),
                              label: Text(
                                'Clear Image',
                                style: GoogleFonts.poppins(color: Colors.red),
                              ),
                            ),
                          ],
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
                            onPressed: _isLoading ? null : _captureImage,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(
                              'Capture Image',
                              style: GoogleFonts.poppins(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.01,
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
                            onPressed: _isLoading ? null : _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: Text(
                              'Upload Image',
                              style: GoogleFonts.poppins(),
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
                      final result = await _analyzeImage();
                      setState(() {
                        _analysisResult = result;
                        _isLoading = false;
                        _isAnalysisRequested = false;
                      });
                      if (result.contains('Positive')) {
                        _showAlertWithAnimation();
                      } else if (result.contains('Negative') && !result.contains('Error')) {
                        _showSuccessMessage();
                      }
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
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    )
                        : Text(
                      'Analyze Image',
                      style: GoogleFonts.poppins(fontSize: screenWidth * 0.045),
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
                                  _analysisResult.contains('Positive')
                                      ? Icons.warning_amber_rounded
                                      : _analysisResult.contains('Negative') && !_analysisResult.contains('Error')
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _analysisResult.contains('Positive')
                                      ? Colors.red
                                      : _analysisResult.contains('Negative') && !_analysisResult.contains('Error')
                                      ? Colors.green
                                      : Colors.grey,
                                  size: screenWidth * 0.06,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  'Analysis Result',
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              _analysisResult,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.035,
                                height: 1.5,
                                color: _analysisResult.contains('Positive')
                                    ? Colors.red[700]
                                    : _analysisResult.contains('Negative') && !_analysisResult.contains('Error')
                                    ? Colors.green[700]
                                    : Colors.black,
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
    );
  }
}
