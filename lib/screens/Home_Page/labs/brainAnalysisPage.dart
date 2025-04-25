import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart'; // للأنيميشن

class BrainAnalysisPage extends StatefulWidget {
  @override
  _BrainAnalysisPageState createState() => _BrainAnalysisPageState();
}

class _BrainAnalysisPageState extends State<BrainAnalysisPage> {
  Interpreter? _interpreter;
  File? _image;
  String _result = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_brain_tumor.tflite');
      print('Brain Tumor Model Loaded Successfully');
      print('Input shape: ${_interpreter?.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter?.getOutputTensor(0).shape}');
    } catch (e) {
      print('Error loading model: $e');
      setState(() {
        _result = 'Error: Failed to load model ($e)';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = '';
        print('Image picked: ${pickedFile.path}');
      });
      _runInference();
    } else {
      print('No image selected');
    }
  }

  Future<void> _runInference() async {
    if (_interpreter == null) {
      print('Interpreter is null, model not loaded');
      setState(() {
        _result = 'Error: Model not loaded';
        _isLoading = false;
      });
      return;
    }
    if (_image == null) {
      print('No image to process');
      setState(() {
        _result = 'Error: No image selected';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final input = await _preprocessImage(_image!);
    print('Input prepared with shape: ${input.length} (${input[0].length}x${input[0][0].length}x${input[0][0][0].length})');

    var outputShape = _interpreter!.getOutputTensor(0).shape;
    var output = List.filled(outputShape.reduce((a, b) => a * b), 0).reshape(outputShape);
    print('Output initialized with shape: $outputShape');

    try {
      _interpreter!.run(input, output);
      print('Inference completed, Raw Output: $output');
    } catch (e) {
      print('Error running inference: $e');
      setState(() {
        _result = 'Error: Inference failed ($e)';
        _isLoading = false;
      });
      return;
    }

    String result;
    if (outputShape[1] == 2) {
      result = output[0][0] > output[0][1] ? 'Negative (No Tumor)' : 'Positive (Tumor Detected)';
    } else {
      result = 'Unknown result format, Output: $output';
    }
    print('Result calculated: $result');

    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  Future<List> _preprocessImage(File image) async {
    final bytes = await image.readAsBytes();
    img.Image? decodedImg = img.decodeImage(bytes);
    if (decodedImg == null) {
      print('Failed to decode image');
      throw Exception('Image decoding failed');
    }

    print('Original Image Size: ${decodedImg.width}x${decodedImg.height}');
    img.Image resizedImg = img.copyResize(decodedImg, width: 224, height: 224);
    print('Resized Image Size: ${resizedImg.width}x${resizedImg.height}');

    List input = resizedImg.getBytes().map((byte) => byte / 255.0).toList().reshape([1, 224, 224, 3]);
    return input;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Brain Analysis',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[100]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // عرض الصورة مع أنيميشن
                _image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    _image!,
                    height: 250,
                    width: 250,
                    fit: BoxFit.cover,
                  ).animate().fadeIn(duration: 500.ms).scale(),
                )
                    : Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                ).animate().fadeIn(duration: 500.ms).shake(),
                SizedBox(height: 30),

                // زرار محسن مع أنيميشن
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text(
                    'Pick an Image',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.easeInOut).then().fadeIn(),
                SizedBox(height: 30),

                // عرض النتيجة مع أنيميشن ومعلومات إضافية
                _isLoading
                    ? CircularProgressIndicator(color: Colors.blue[900])
                    .animate()
                    .rotate(duration: 1000.ms)
                    .scale()
                    : _result.isNotEmpty
                    ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // تغيير لون النصوص بناءً على النتيجة
                    Text(
                      _result,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _result.contains('Negative') ? Colors.green[900] : _result.contains('Positive') ? Colors.red[900] : Colors.blue[900],
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 600.ms).slideY(),
                    SizedBox(height: 10),
                    _buildResultInfo(_result),
                  ],
                )
                    : Text(
                  'Upload an image to analyze',
                  style: TextStyle(fontSize: 18, color: Colors.blue[900]),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة لعرض معلومات إضافية بناءً على النتيجة
  Widget _buildResultInfo(String result) {
    if (result.contains('Positive (Tumor Detected)')) {
      return Container(
        padding: EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Recommendation: Please consult a doctor immediately for further diagnosis and treatment.',
              style: TextStyle(fontSize: 16, color: Colors.red[900]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 700.ms);
    } else if (result.contains('Negative (No Tumor)')) {
      return Container(
        padding: EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Good News! No tumor detected. Regular check-ups are recommended.',
              style: TextStyle(fontSize: 16, color: Colors.green[900]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 700.ms);
    } else {
      return Container();
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}
