import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import 'ChatWithAIPage.dart';
import 'heartAnalysisPage.dart';
import 'kidneyAnalysisPage.dart';
import 'liverAnalysisPage.dart';
import 'skinAnalysisPage.dart';
import 'brainAnalysisPage.dart';
import 'pneumoniaAnalysisPage.dart';

class LabsAndScansPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Labs & Scans'),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLabButton('Chat with AI', 'assets/animation/AnimationPharmacy1743042089415.json', () {
                    Navigator.push(context, _createSlideRoute(ChatWithAIPage()));
                  }),
                  SizedBox(height: 20),
                  _buildLabButton('Heart Analysis', 'assets/heart_analysis.png', () {
                    Navigator.push(context, _createSlideRoute(HeartAnalysisPage()));
                  }),
                  SizedBox(height: 20),
                  _buildLabButton('Liver Analysis', 'assets/liver_analysis.png', () {
                    Navigator.push(context, _createSlideRoute(LiverAnalysisPage()));
                  }),
                  SizedBox(height: 20),
                  _buildLabButton('Kidney Analysis', 'assets/kidney_analysis.png', () {
                    Navigator.push(context, _createSlideRoute(KidneyAnalysisPage()));
                  }),
                  SizedBox(height: 20),
                  _buildLabButton('Skin Analysis', 'assets/skin_analysis.png', () {
                    Navigator.push(context, _createSlideRoute(SkinAnalysisPage()));
                  }),
                  SizedBox(height: 20),
                  _buildLabButton('Brain Analysis', 'assets/brain_analysis.png', () {
                    Navigator.push(context, _createSlideRoute(BrainAnalysisPage()));
                  }),
                  SizedBox(height: 20),
                  _buildLabButton('Pneumonia Detection', 'assets/pneumonia_analysis.png', () {
                    Navigator.push(context, _createSlideRoute(PneumoniaAnalysisPage()));
                  }),
                  SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تصميم كل زر في الصفحة
  static Widget _buildLabButton(String title, String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.blue.withOpacity(0.2),
      highlightColor: Colors.blue.withOpacity(0.2),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 10, offset: Offset(0, 5)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white, // تغيير لون الخلفية إلى الأبيض
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: imagePath.endsWith('.json')
                      ? Lottie.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  )
                      : Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms).scale();
  }
}

// دالة الانتقال بين الصفحات
PageRouteBuilder _createSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(position: animation.drive(Tween(begin: Offset(1.0, 0.0), end: Offset.zero)), child: child);
    },
    transitionDuration: Duration(milliseconds: 500),
  );
}