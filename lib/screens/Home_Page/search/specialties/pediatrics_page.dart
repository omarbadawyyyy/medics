import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/search/specialties/specialty_page.dart';

class PediatricsPage extends StatelessWidget {
  final List<String> doctors = [
    'Dr. Samir Ali',
    'Dr. Mona Ahmed',
    'Dr. Karim Mohamed',
  ];

  @override
  Widget build(BuildContext context) {
    return SpecialtyPage(
      specialtyName: 'Pediatrics and New Born',
      doctors: doctors,
    );
  }
}