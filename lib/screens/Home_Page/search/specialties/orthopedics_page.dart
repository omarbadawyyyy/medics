import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/search/specialties/specialty_page.dart';

class OrthopedicsPage extends StatelessWidget {
  final List<String> doctors = [
    'Dr. Mahmoud Ahmed',
    'Dr. Nada Samir',
    'Dr. Hossam Ali',
  ];

  @override
  Widget build(BuildContext context) {
    return SpecialtyPage(
      specialtyName: 'Orthopedics',
      doctors: doctors,
    );
  }
}