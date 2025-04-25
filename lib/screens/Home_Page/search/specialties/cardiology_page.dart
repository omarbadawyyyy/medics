import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/search/specialties/specialty_page.dart';

class CardiologyPage extends StatelessWidget {
  final List<String> doctors = [
    'Dr. Ahmed Samir',
    'Dr. Mona Ali',
    'Dr. Khaled Mohamed',
  ];

  @override
  Widget build(BuildContext context) {
    return SpecialtyPage(
      specialtyName: 'Cardiology and Vascular Disease',
      doctors: doctors,
    );
  }
}