import 'package:flutter/material.dart';
import 'specialty_page.dart'; // استيراد SpecialtyPage

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<String> _specialties = [
    'Dermatology',
    'Dentistry',
    'Psychiatry',
    'Pediatrics and New Born',
    'Neurology',
    'Orthopedics',
    'Gynaecology and Infertility',
    'Ear, Nose and Throat',
    'Cardiology and Vascular Disease',
    'Internal Medicine',
  ];

  String _searchQuery = '';

  List<String> _filteredSpecialties = [];

  @override
  void initState() {
    super.initState();
    _filteredSpecialties = _specialties;
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      _filteredSpecialties = _specialties
          .where((specialty) =>
          specialty.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // دالة لتحويل اسم التخصص إلى الاسم المستخدم في قاعدة البيانات
  String _mapSpecialtyName(String specialty) {
    switch (specialty) {
      case 'Pediatrics and New Born':
        return 'Pediatrics';
      case 'Gynaecology and Infertility':
        return 'Gynecology';
      case 'Ear, Nose and Throat':
        return 'Ear (ENT)';
      case 'Cardiology and Vascular Disease':
        return 'Cardiology';
      default:
        return specialty;
    }
  }

  void _navigateToSpecialtyPage(BuildContext context, String specialty) {
    // تحويل اسم التخصص إلى الاسم المستخدم في قاعدة البيانات
    String mappedSpecialty = _mapSpecialtyName(specialty);

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500), // مدة الانيميشن
        pageBuilder: (context, animation, secondaryAnimation) =>
            SpecialtyPage(specialty: mappedSpecialty),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1.0, 0.0); // بداية الانيميشن من اليمين
          var end = Offset.zero; // نهاية الانيميشن
          var curve = Curves.easeInOutQuart; // Curve للانيميشن
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Search for Doctor'),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for specialty, doctor, or hospital',
                prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue[900]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue[900]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue[900]!),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _updateSearchQuery,
            ),
            const SizedBox(height: 20),
            Text(
              'Most Popular Specialties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: _filteredSpecialties
                    .map((specialty) => _buildSpecialtyItem(specialty))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtyItem(String specialty) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Image.asset(
          'assets/$specialty.png',
          width: 40,
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.medical_services, color: Colors.blue[900]);
          },
        ),
        title: Text(
          specialty,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: () {
          _navigateToSpecialtyPage(context, specialty); // الانتقال إلى صفحة التخصص
        },
      ),
    );
  }
}