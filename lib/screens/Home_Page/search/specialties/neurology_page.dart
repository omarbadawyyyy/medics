import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/search/specialties/specialty_page.dart';

class NeurologyPage extends StatelessWidget {
  final List<String> doctors = [
    'Dr. Ahmed Samir',
    'Dr. Rana Mohamed',
    'Dr. Tarek Ali',
  ];

  @override
  Widget build(BuildContext context) {
    return SpecialtyPage(
      specialtyName: 'Neurology',
      doctors: doctors,
    );
  }
}