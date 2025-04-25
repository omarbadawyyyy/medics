import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/search/specialties/specialty_page.dart';

class PsychiatryPage extends StatelessWidget {
  final List<String> doctors = [
    'Dr. Ali Mohamed',
    'Dr. Hana Ahmed',
    'Dr. Youssef Khaled',
  ];

  @override
  Widget build(BuildContext context) {
    return SpecialtyPage(
      specialtyName: 'Psychiatry',
      doctors: doctors,
    );
  }
}