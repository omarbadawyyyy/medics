import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../my_profile/screens_myProfil/my_account_screens/address_managment/address_management_page.dart';
import 'specialty_page.dart';
import '../doctor_call/doctor_call_specialty_page.dart';

class SearchPage extends StatefulWidget {
  final String source;
  final String email;

  const SearchPage({super.key, required this.source, required this.email});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<String> _specialties = const [
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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _filteredSpecialties = _specialties;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preloadImages();
  }

  void _preloadImages() {
    for (var specialty in _specialties) {
      precacheImage(AssetImage('assets/$specialty.png'), context);
    }
  }

  void _updateSearchQuery(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
        _filteredSpecialties = _specialties
            .where((specialty) =>
            specialty.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    });
  }

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
    String mappedSpecialty = _mapSpecialtyName(specialty);

    Widget targetPage;
    switch (widget.source) {
      case 'doctor_call':
        targetPage = DoctorCallSpecialtyPage(specialty: mappedSpecialty);
        break;
      case 'doctor_visit':
        targetPage = AddressManagementPage(
          email: widget.email,
          source: widget.source,
          specialty: mappedSpecialty,
        );
        break;
      case 'client_visit':
      default:
        targetPage = SpecialtyPage(specialty: mappedSpecialty);
        break;
    }

    Navigator.push(context, _createSlideRoute(targetPage));
  }

  PageRouteBuilder _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.fastOutSlowIn;
        var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        var slideAnimation = animation.drive(slideTween);
        var fadeAnimation = animation.drive(fadeTween);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
            const Text(
              'Most Popular Specialties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                cacheExtent: 9999,
                clipBehavior: Clip.hardEdge,
                itemCount: _filteredSpecialties.length,
                itemBuilder: (context, index) {
                  return _buildSpecialtyItem(
                    _filteredSpecialties[index],
                    delay: (index * 100).ms,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtyItem(String specialty, {Duration delay = Duration.zero}) {
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
          _navigateToSpecialtyPage(context, specialty);
        },
      ),
    ).animate().fadeIn(
      duration: 400.ms,
      delay: delay,
    ).slideY(
      begin: 0.3,
      end: 0.0,
      duration: 400.ms,
      curve: Curves.easeOutCubic,
    );
  }
}
