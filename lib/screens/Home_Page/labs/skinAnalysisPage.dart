import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:math'; // لاستخدام exp
import 'package:flutter_animate/flutter_animate.dart'; // لتطبيق الأنميشن

class SkinAnalysisPage extends StatefulWidget {
  @override
  _SkinAnalysisPageState createState() => _SkinAnalysisPageState();
}

class _SkinAnalysisPageState extends State<SkinAnalysisPage> {
  late Interpreter _interpreter;
  File? _image;
  String? _prediction;
  bool _isLoading = false;

  // Labels for the 7 classes based on HAM10000 dataset
  final List<String> labelsEn = [
    'Actinic Keratosis (akiec)',  // Precancerous lesion
    'Basal Cell Carcinoma (bcc)', // Cancerous
    'Benign Keratosis (bkl)',     // Benign
    'Dermatofibroma (df)',        // Benign
    'Melanoma (mel)',             // Cancerous
    'Melanocytic Nevi (nv)',      // Typically benign
    'Vascular Lesions (vasc)',    // Typically benign
  ];

  // Indices of cancerous classes (bcc and mel)
  final List<int> cancerousIndices = [1, 4]; // 1: bcc, 4: mel

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/skin-lesion-class.tflite');
      print("Model loaded successfully");
    } catch (e) {
      print("Error loading model: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load model: $e")),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _prediction = null;
      });
      await _analyzeImage(_image!);
    }
  }

  Future<void> _analyzeImage(File image) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<List<List<List<double>>>> input = await _preprocessImage(image);

      // Output shape: [1, 7] for 7 classes
      var output = List.filled(1 * 7, 0).reshape([1, 7]);
      _interpreter.run(input, output);

      // Print raw output for debugging
      print("Raw output: $output");
      for (int i = 0; i < 7; i++) {
        print("Class ${labelsEn[i]}: ${output[0][i]}");
      }

      // Apply Softmax to convert logits to probabilities
      List<double> probabilities = softmax(output[0]);

      // Find the class with the highest probability
      double maxProbability = probabilities[0];
      int predictedClassIndex = 0;
      for (int i = 1; i < 7; i++) {
        if (probabilities[i] > maxProbability) {
          maxProbability = probabilities[i];
          predictedClassIndex = i;
        }
      }

      double confidence = maxProbability * 100;

      // Check if the predicted class is cancerous
      bool isCancerous = cancerousIndices.contains(predictedClassIndex);

      // Build the basic result text
      String resultText = "Result: ${labelsEn[predictedClassIndex]}\n"
          "Confidence: ${confidence.toStringAsFixed(2)}%\n"
          "Cancer Status: ${confidence > 60 ? "Positive" : "Negative"}";

      // Add probabilities and warning only if Positive
      if (confidence > 60) {
        String probabilitiesText = "\n\nProbabilities:\n";
        for (int i = 0; i < 7; i++) {
          probabilitiesText += "${labelsEn[i]}: ${(probabilities[i] * 100).toStringAsFixed(2)}%\n";
        }
        resultText += probabilitiesText;
        resultText += '\n\n⚠️ **Warning:** This is a cancerous condition. Please visit a hospital immediately for professional medical advice.';
        // Trigger strong warning dialog
        _showCancerWarning();
      }

      setState(() {
        _prediction = resultText;
      });
    } catch (e) {
      print("Error analyzing image: $e");
      setState(() {
        _prediction = "Error analyzing image: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Softmax function to convert logits to probabilities
  List<double> softmax(List<double> logits) {
    double maxLogit = logits.reduce((a, b) => a > b ? a : b);
    List<double> expValues = logits.map((z) => exp(z - maxLogit)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((expValue) => expValue / sumExp).toList();
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(File image) async {
    // Read the image
    final imageData = await image.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);

    // Resize to 150x150 to match the model's training input
    img.Image resizedImage = img.copyResize(originalImage!, width: 150, height: 150);

    // Get image data as bytes
    List<int> byteData = resizedImage.getBytes(order: img.ChannelOrder.rgb);

    // Initialize input with shape [1, 150, 150, 3]
    List<List<List<List<double>>>> input = List.generate(
      1, // batch size
          (batch) => List.generate(
        150, // height
            (y) => List.generate(
          150, // width
              (x) => List<double>.filled(
            3, // channels (RGB)
            0.0,
          ),
        ),
      ),
    );

    // Fill the input with normalized values
    for (int y = 0; y < 150; y++) {
      for (int x = 0; x < 150; x++) {
        int pixelIndex = (y * 150 + x) * 3;
        input[0][y][x][0] = byteData[pixelIndex] / 255.0;     // R
        input[0][y][x][1] = byteData[pixelIndex + 1] / 255.0; // G
        input[0][y][x][2] = byteData[pixelIndex + 2] / 255.0; // B
      }
    }

    return input;
  }

  // Show a strong warning dialog for cancerous lesions
  void _showCancerWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Warning: Cancerous Skin Lesion',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(
            'This lesion may be cancerous. Please visit a hospital immediately for professional medical advice.',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Skin Lesion Analysis",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[900], // تعديل اللون إلى الأزرق
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200],
              ),
              child: _image == null
                  ? Center(child: Text("No image selected"))
                  : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _image!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: Icon(Icons.image),
              label: Text("Pick Image from Gallery"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                backgroundColor: Colors.blue[900], // اللون الأزرق
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else if (_prediction != null)
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1), // تغيير اللون مع الشفافية
                  borderRadius: BorderRadius.circular(10),
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    children: [
                      TextSpan(text: "Result: ${labelsEn[_getPredictedClassIndex(_prediction!)]}\n"),
                      TextSpan(text: "Confidence: ${_getConfidence(_prediction!)}%\n"),
                      TextSpan(
                        text: "Cancer Status: ",
                      ),
                      TextSpan(
                        text: _getCancerStatus(_prediction!),
                        style: TextStyle(
                          color: _getCancerStatus(_prediction!) == "Positive" ? Colors.red : Colors.green,
                        ),
                      ),
                      if (_getCancerStatus(_prediction!) == "Positive") ...[
                        TextSpan(text: "\n\n"),
                        TextSpan(text: _getProbabilities(_prediction!)),
                        TextSpan(
                          text: '\n\n⚠️ **Warning:** This is a cancerous condition. Please visit a hospital immediately for professional medical advice.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ).animate().fade(duration: 400.ms), // إضافة الأنميشن
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods to parse the prediction string
  int _getPredictedClassIndex(String prediction) {
    String resultLine = prediction.split('\n')[0]; // "Result: ..."
    String label = resultLine.split(': ')[1];
    return labelsEn.indexOf(label);
  }

  String _getConfidence(String prediction) {
    String confidenceLine = prediction.split('\n')[1]; // "Confidence: ..."
    return confidenceLine.split(': ')[1].replaceAll('%', '');
  }

  String _getCancerStatus(String prediction) {
    String statusLine = prediction.split('\n')[2]; // "Cancer Status: ..."
    return statusLine.split(': ')[1];
  }

  String _getProbabilities(String prediction) {
    List<String> lines = prediction.split('\n');
    int startIndex = lines.indexOf("Probabilities:");
    if (startIndex == -1) return ""; // إذا لم يكن هناك Probabilities
    return lines.sublist(startIndex, startIndex + 8).join('\n'); // 8 لأن هناك 7 احتمالات + العنوان
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }
}