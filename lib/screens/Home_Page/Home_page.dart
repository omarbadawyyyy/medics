import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:medics/screens/Home_Page/pharmacy/pharmacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ShamelPage.dart';
import 'ask_a_doctor.dart';
import 'bmi/bmi_calculator_page.dart';
import 'labs/LabsAndScansPage.dart';
import 'my_activity_page.dart';
import 'my_profile/my_profile_page.dart';
import 'search/search_page.dart';

class HomePage extends StatefulWidget {
  final String email;
  final String name;
  final String phone;
  final String? imagePath;

  const HomePage({
    required this.email,
    required this.name,
    required this.phone,
    this.imagePath,
    Key? key,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    print('Email received in HomePage: ${widget.email}'); // للتأكد من الـ email
    _pages = [
      HomeContent(email: widget.email),
      MyActivityPage(),
      MyProfilePage(email: widget.email),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 100,
          automaticallyImplyLeading: false,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(left: 20, top: 15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Medics',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _pages[_selectedIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.article), label: 'My Activity'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My Profile'),
          ],
          selectedItemColor: Colors.blue[900],
          unselectedItemColor: Colors.grey,
        ).animate().slide(duration: 400.ms),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final String email;

  const HomeContent({required this.email, Key? key}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    print('Email received in HomeContent: ${widget.email}'); // للتأكد من الـ email
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(widget.email)
          .get();
      setState(() {
        _isSubscribed = doc.exists && (doc['isSubscribed'] ?? false);
        print('Subscription Status in HomeContent: $_isSubscribed');
      });
    } catch (e) {
      print('Error loading subscription status in HomeContent: $e');
    }
  }

  Future<void> _navigateToShamelPage(BuildContext context) async {
    await Navigator.push(context, _createSlideRoute(ShamelPage(email: widget.email)));
    await _loadSubscriptionStatus();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildContainer('Clinic Visit', 'assets/clinic_visit.png', () {
                  Navigator.push(context, _createSlideRoute(SearchPage()));
                }),
                _buildContainer('Pharmacy', 'assets/pharmacy.png', () {
                  print('Navigating to PharmacyPage with email: ${widget.email}'); // للتأكد من الـ email
                  Navigator.push(context, _createSlideRoute(PharmacyPage(email: widget.email)));
                }),
                _buildContainer('Doctor Call', 'assets/doctor_call.png', () {}),
                _buildContainer('Home Care', 'assets/home_care.png', () {}),
                _buildContainer('Procedures', 'assets/procedures.png', () {}),
                InkWell(
                  onTap: () {
                    Navigator.push(context, _createSlideRoute(LabsAndScansPage()));
                  },
                  splashColor: Colors.blue.withOpacity(0.2),
                  highlightColor: Colors.blue.withOpacity(0.2),
                  child: Material(
                    color: Colors.transparent,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: 'Labs & Scans',
                            child: Lottie.asset(
                              'assets/animation/AI1742427287201.json',
                              height: 65,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 0.0001),
                          const Text(
                            'Labs & Scans',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade(duration: 300.ms).scale(),
              ],
            ),
          ).animate().fade(duration: 500.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 20),
          _buildSearchBar(context),
          _buildShamelBanner(context, _isSubscribed, _navigateToShamelPage),
          _buildActionContainer('Have a Medical Question?', 'assets/medical_question.png', 'Ask Now', () {
            Navigator.push(context, _createSlideRoute(AskADoctorPage()));
          }),
          _buildActionContainer('Calculate your BMI', 'assets/bmi.png', 'Calculate', () {
            Navigator.push(context, _createSlideRoute(BMICalculatorPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildContainer(String title, String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.blue.withOpacity(0.2),
      highlightColor: Colors.blue.withOpacity(0.2),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: title,
                child: Image.asset(imagePath, height: 50),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 300.ms).scale();
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () => Navigator.push(context, _createSlideRoute(SearchPage())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Search for specialty, doctor, or hospital',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ).animate().fade().slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildShamelBanner(
      BuildContext context, bool isSubscribed, Future<void> Function(BuildContext) navigateToShamelPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        onTap: () => navigateToShamelPage(context),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: isSubscribed ? const Color(0xFFCAAD0C) : Colors.blue[600],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Image.asset('assets/Shamel.png', width: 70, height: 90),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shamel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSubscribed
                          ? 'Activated'
                          : 'Save up to 80% on all medical services with Shamel.',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    ).animate().fade().slideY(begin: 0.3, end: 0);
  }

  Widget _buildActionContainer(String title, String imagePath, String buttonText, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(imagePath, width: 50, height: 50),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('Click to proceed', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
              child: Text(buttonText, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).animate().fade().slideY(begin: 0.3, end: 0);
  }
}

PageRouteBuilder _createSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 500),
  );
}