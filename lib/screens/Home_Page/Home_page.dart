import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:medics/screens/Home_Page/pharmacy/pharmacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medics/screens/Home_Page/search/doctor_profile_page.dart';
import 'package:medics/screens/Home_Page/search/doctors_data.dart';
import 'ShamelPage.dart';
import 'ask_a_doctor.dart';
import 'bmi/bmi_calculator_page.dart';
import 'home_care/HomeCare.dart';
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
    print('Email received in HomePage: ${widget.email}');
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
      onWillPop: () async => false, // Prevent back button from exiting the app
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
  String _selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    print('Email received in HomeContent: ${widget.email}');
    _loadSubscriptionStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  String _mapSpecialtyToImageName(String specialty) {
    switch (specialty) {
      case 'Pediatrics':
        return 'Pediatrics and New Born';
      case 'Gynecology':
        return 'Gynaecology and Infertility';
      case 'Ear (ENT)':
        return 'Ear, Nose and Throat';
      case 'Cardiology':
        return 'Cardiology and Vascular Disease';
      default:
        return specialty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      clipBehavior: Clip.hardEdge,
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
                  Navigator.push(
                    context,
                    _createSlideRoute(
                      SearchPage(source: 'client_visit', email: widget.email),
                    ),
                  );
                }),
                _buildContainer('Pharmacy', 'assets/pharmacy.png', () {
                  print('Navigating to PharmacyPage with email: ${widget.email}');
                  Navigator.push(
                    context,
                    _createSlideRoute(PharmacyPage(email: widget.email)),
                  );
                }),
                _buildContainer('Doctor Call', 'assets/doctor_call.png', () {
                  Navigator.push(
                    context,
                    _createSlideRoute(
                      SearchPage(source: 'doctor_call', email: widget.email),
                    ),
                  );
                }),
                _buildContainer('Home Care', 'assets/home_care.png', () {
                  Navigator.push(
                    context,
                    _createSlideRoute(HomeCarePage(email: widget.email)),
                  );
                }),
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
          _buildFeaturedDoctors(),
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
        onTap: () => Navigator.push(
          context,
          _createSlideRoute(SearchPage(source: 'client_visit', email: widget.email)),
        ),
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

  Widget _buildFeaturedDoctors() {
    final filteredDoctors = _selectedCategory == 'All'
        ? DoctorsData.doctors
        : DoctorsData.doctors.where((doctor) => doctor.specialty == _selectedCategory).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Doctors',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward, color: Colors.blue[900]),
                  onPressed: () {
                    Navigator.push(
                      context,
                      _createSlideRoute(SearchPage(source: 'client_visit', email: widget.email)),
                    );
                  },
                  tooltip: 'View all doctors',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  'All',
                  'Cardiology',
                  'Dentistry',
                  'Dermatology',
                  'Ear (ENT)',
                  'Gynecology',
                  'Internal Medicine',
                  'Neurology',
                  'Orthopedics',
                  'Pediatrics',
                  'Psychiatry'
                ].map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : 'All';
                        });
                      },
                      selectedColor: Colors.blue[900],
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: _selectedCategory == category ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: filteredDoctors.length,
                itemBuilder: (context, index) {
                  final doctor = filteredDoctors[index];
                  String imageSpecialtyName = _mapSpecialtyToImageName(doctor.specialty);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        _createSlideRoute(DoctorProfilePage(doctor: doctor)),
                      );
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3)),
                        ],
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[400]!, width: 2),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                  child: Image.asset(
                                    doctor.imageUrl,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      'assets/images/default_doctor.png',
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        doctor.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/$imageSpecialtyName.png',
                                      width: 18,
                                      height: 18,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.medical_services,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        doctor.specialty,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.blue[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        doctor.location.split(':')[1].trim(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.3, end: 0);
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
                        fontSize: 30,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
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