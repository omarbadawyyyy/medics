import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/search/specialties/specialty_page.dart';

class EntPage extends StatelessWidget {
  final List<String> doctors = [
    'Dr. Mohamed Samir',
    'Dr. Rania Ahmed',
    'Dr. Ali Karim',
  ];

  @override
  Widget build(BuildContext context) {
    return SpecialtyPage(
      specialtyName: 'Ear, Nose and Throat',
      doctors: doctors,
    );
  }
}