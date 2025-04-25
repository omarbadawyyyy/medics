import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/search/specialties/specialty_page.dart';

class DermatologyPage extends StatelessWidget {
  final List<String> doctors = [
    'Dr. Ahmed Ali',
    'Dr. Sara Mohamed',
    'Dr. Omar Khaled',
  ];

  @override
  Widget build(BuildContext context) {
    return SpecialtyPage(
      specialtyName: 'Dermatology',
      doctors: doctors,
    );
  }
}