import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/search/specialties/specialty_page.dart';

class DentistryPage extends StatelessWidget {
  final List<String> doctors = [
    'Dr. Mohamed Hassan',
    'Dr. Fatma Mahmoud',
    'Dr. Khaled Samir',
  ];

  @override
  Widget build(BuildContext context) {
    return SpecialtyPage(
      specialtyName: 'Dentistry',
      doctors: doctors,
    );
  }
}