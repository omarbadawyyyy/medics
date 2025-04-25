import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/search/specialties/specialty_page.dart';

class InternalMedicinePage extends StatelessWidget {
  final List<String> doctors = [
    'Dr. Samir Ahmed',
    'Dr. Hana Mohamed',
    'Dr. Ali Karim',
  ];

  @override
  Widget build(BuildContext context) {
    return SpecialtyPage(
      specialtyName: 'Internal Medicine',
      doctors: doctors,
    );
  }
}