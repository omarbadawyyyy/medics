import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

import 'BloodTestAnalysisPage.dart';
import 'ChatWithAIPage.dart';
import 'EyeAnalysisPage.dart';
import 'heartAnalysisPage.dart';
import 'kidneyAnalysisPage.dart';
import 'liverAnalysisPage.dart';
import 'skinAnalysisPage.dart';
import 'brainAnalysisPage.dart';
import 'pneumoniaAnalysisPage.dart';
import 'EyeAnalysisPage.dart';
import 'BloodTestAnalysisPage.dart';

class LabsAndScansPage extends StatefulWidget {
  const LabsAndScansPage({super.key});

  @override
  _LabsAndScansPageState createState() => _LabsAndScansPageState();
}

class _LabsAndScansPageState extends State<LabsAndScansPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheLottieAssets();
  }

  void precacheLottieAssets() {
    precacheImage(
      const AssetImage('assets/animation/AnimationPharmacy1743042089415.json'),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Labs & Scans',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[900],
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: _labButtons.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final button = _labButtons[index];
          return _buildLabButton(
            button.title,
            button.imagePath,
            button.onTap,
            delay: (index * 100).ms,
          );
        },
      ),
    );
  }

  List<_LabButtonData> get _labButtons => [
    _LabButtonData('Chat with AI', 'assets/animation/AnimationPharmacy1743042089415.json', () {
      Navigator.push(context, _createSlideRoute( ChatWithAIPage()));
    }),
    _LabButtonData('Heart Analysis', 'assets/heart_analysis.png', () {
      Navigator.push(context, _createSlideRoute(const HeartAnalysisPage()));
    }),
    _LabButtonData('Liver Analysis', 'assets/liver_analysis.png', () {
      Navigator.push(context, _createSlideRoute( LiverAnalysisPage()));
    }),
    _LabButtonData('Kidney Analysis', 'assets/kidney_analysis.png', () {
      Navigator.push(context, _createSlideRoute( KidneyAnalysisPage()));
    }),
    _LabButtonData('Skin Analysis', 'assets/skin_analysis.png', () {
      Navigator.push(context, _createSlideRoute( SkinAnalysisPage()));
    }),
    _LabButtonData('Brain Analysis', 'assets/brain_analysis.png', () {
      Navigator.push(context, _createSlideRoute( BrainAnalysisPage()));
    }),
    _LabButtonData('Pneumonia Detection', 'assets/pneumonia_analysis.png', () {
      Navigator.push(context, _createSlideRoute( PneumoniaAnalysisPage()));
    }),
    _LabButtonData('Eye Analysis', 'assets/Eye_analysis.png', () {
      Navigator.push(context, _createSlideRoute( EyeAnalysisPage()));
    }),
    _LabButtonData('Blood Test Analysis', 'assets/Blood_test_analysis.png', () {
      Navigator.push(context, _createSlideRoute( BloodAnalysisPage()));
    }),
  ];

  Widget _buildLabButton(String title, String imagePath, VoidCallback onTap, {Duration delay = Duration.zero}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: imagePath.endsWith('.json')
                    ? Lottie.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  repeat: true,
                )
                    : Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue[900],
                size: 20,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms, delay: delay).slideY(
        begin: 0.3,
        end: 0.0,
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  PageRouteBuilder _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

class _LabButtonData {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  _LabButtonData(this.title, this.imagePath, this.onTap);
}
