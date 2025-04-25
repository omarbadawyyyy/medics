import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/search/specialties/specialty_page.dart';

class GynaecologyPage extends StatelessWidget {
  final List<String> doctors = [
    'Dr. Ahmed Youssef',
    'Dr. Samia Mohamed',
    'Dr. Karim Ali',
  ];

  @override
  Widget build(BuildContext context) {
    return SpecialtyPage(
      specialtyName: 'Gynaecology and Infertility',
      doctors: doctors,
    );
  }
}