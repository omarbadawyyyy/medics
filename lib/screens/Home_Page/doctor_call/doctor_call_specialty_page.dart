import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../search/booking_confirmation_page.dart';
import '../search/doctor_profile_page.dart';
import '../search/doctors_data.dart';

class DoctorCallSpecialtyPage extends StatefulWidget {
  final String specialty;

  const DoctorCallSpecialtyPage({Key? key, required this.specialty}) : super(key: key);

  @override
  _DoctorCallSpecialtyPageState createState() => _DoctorCallSpecialtyPageState();
}

class _DoctorCallSpecialtyPageState extends State<DoctorCallSpecialtyPage> {
  List<Doctor>? _filteredDoctors;
  String _searchQuery = '';
  String _sortOption = 'Most Recommended';
  Map<String, dynamic> _filters = {};
  bool _isLoading = true;
  int _pageSize = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    print('Static Doctors count: ${DoctorsData.doctors.length}');
    for (var doctor in DoctorsData.doctors) {
      print('Static Doctor: ${doctor.name}, Specialty: ${doctor.specialty}, Bio: ${doctor.bio}, Reviews: ${doctor.reviews?.length ?? 0}');
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _filteredDoctors = null;
    });
    // Data is now handled by StreamBuilder
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMoreDoctors(List<Doctor> allDoctors) async {
    if (!_hasMore || _isLoading || _filteredDoctors == null) return;
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      final nextDoctors = allDoctors
          .skip(_filteredDoctors!.length)
          .take(_pageSize)
          .toList();
      _filteredDoctors = [..._filteredDoctors!, ...nextDoctors];
      _hasMore = nextDoctors.length == _pageSize;
      _isLoading = false;
    });
  }

  void _searchDoctors(String query) {
    setState(() {
      _searchQuery = query;
      _applyFiltersAndSort();
    });
  }

  void _sortDoctors(String option) {
    setState(() {
      _sortOption = option;
      _applyFiltersAndSort();
    });
  }

  void _resetSort() {
    setState(() {
      _sortOption = 'Most Recommended';
      _applyFiltersAndSort();
    });
  }

  void _resetFilters() {
    setState(() {
      _filters = {};
      _applyFiltersAndSort();
    });
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters;
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    // Called within StreamBuilder
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sort',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _resetSort();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  RadioListTile<String>(
                    title: const Text('Most Recommended'),
                    value: 'Most Recommended',
                    groupValue: _sortOption,
                    activeColor: Colors.blue[800],
                    onChanged: (value) {
                      _sortDoctors(value!);
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Price Low to High'),
                    value: 'Price Low to High',
                    groupValue: _sortOption,
                    activeColor: Colors.blue[800],
                    onChanged: (value) {
                      _sortDoctors(value!);
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Price High to Low'),
                    value: 'Price High to Low',
                    groupValue: _sortOption,
                    activeColor: Colors.blue[800],
                    onChanged: (value) {
                      _sortDoctors(value!);
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Short Waiting Time'),
                    value: 'Short Waiting Time',
                    groupValue: _sortOption,
                    activeColor: Colors.blue[800],
                    onChanged: (value) {
                      _sortDoctors(value!);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(List<Doctor> allDoctors) {
    final maxFeesController = TextEditingController();
    String? selectedTrait;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter By',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Trait',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: Colors.blue[800]!, width: 2),
                        ),
                      ),
                      items: allDoctors
                          .map((doctor) => doctor.trait)
                          .toSet()
                          .map((trait) => DropdownMenuItem(
                        value: trait,
                        child: Text(trait),
                      ))
                          .toList(),
                      onChanged: (value) {
                        selectedTrait = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: maxFeesController,
                      decoration: InputDecoration(
                        labelText: 'Max Fees (EGP)',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: Colors.blue[800]!, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _resetFilters();
                              maxFeesController.clear();
                              selectedTrait = null;
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final filters = <String, dynamic>{};
                              if (selectedTrait != null) {
                                filters['trait'] = selectedTrait;
                              }
                              if (maxFeesController.text.isNotEmpty) {
                                try {
                                  filters['maxFees'] =
                                      double.parse(maxFeesController.text);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please enter a valid number for fees')),
                                  );
                                  return;
                                }
                              }
                              _applyFilters(filters);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Map View',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('Temporary placeholder for map. To be updated later.'),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 2,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PageRouteBuilder _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var slideAnimation = animation.drive(slideTween);

        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
        var fadeAnimation = animation.drive(fadeTween);

        var scaleTween = Tween<double>(begin: 0.95, end: 1.0).chain(CurveTween(curve: curve));
        var scaleAnimation = animation.drive(scaleTween);

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: SlideTransition(position: slideAnimation, child: child),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 120),
      reverseTransitionDuration: const Duration(milliseconds: 120),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionsBuilder(),
            TargetPlatform.iOS: CustomPageTransitionsBuilder(),
          },
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.specialty} Doctors (Video Call)'),
          backgroundColor: Colors.blue[800],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.grey[200],
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('doctors')
              .where('specialty', isEqualTo: widget.specialty)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('Firestore Error: ${snapshot.error}');
              return const Center(child: Text('Error loading doctors'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Map Firestore doctors
            final firestoreDoctors = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              print('Firestore Doc: $data');
              return Doctor(
                name: data['name'] ?? 'Unknown Doctor',
                specialty: data['specialty'] ?? widget.specialty,
                rating: (data['rating'] ?? 0.0).toDouble(),
                numberOfReviews: data['numberOfReviews'] ?? 0,
                trait: data['trait'] ?? 'General',
                location: data['location'] ?? 'Unknown Location',
                fees: (data['fees'] ?? 100.0).toDouble(),
                waitingTimeMinutes: data['waitingTimeMinutes'] ?? 30,
                availability: data['availability'] ?? 'Not Specified',
                isSponsored: data['isSponsored'] ?? false,
                imageUrl: data['imageUrl'] ?? 'assets/images/default_doctor.png',
                bio: data['bio'] ?? 'No bio available',
                reviews: (data['reviews'] as List<dynamic>?)?.map((review) {
                  final reviewData = review as Map<String, dynamic>;
                  return Review(
                    comment: reviewData['comment'] ?? 'No comment',
                    stars: reviewData['stars'] ?? 0,
                    reviewerName: reviewData['reviewerName'] ?? 'Anonymous',
                  );
                }).toList() ?? [],
              );
            }).toList();

            print('Firestore Doctors Count: ${firestoreDoctors.length}');

            // Get static doctors from DoctorsData
            final staticDoctors = DoctorsData.doctors
                .where((doctor) => doctor.specialty == widget.specialty)
                .toList();
            print('Static Doctors Count: ${staticDoctors.length}');

            // Combine and remove duplicates
            final allDoctorsMap = <String, Doctor>{};
            for (var doctor in [...staticDoctors, ...firestoreDoctors]) {
              allDoctorsMap[doctor.name] = doctor;
            }
            final allDoctors = allDoctorsMap.values.toList();

            print('Total Combined Doctors: ${allDoctors.length}');
            allDoctors.forEach((doctor) {
              print(
                  'Doctor: ${doctor.name}, Specialty: ${doctor.specialty}, Source: ${firestoreDoctors.contains(doctor) ? 'Firestore' : 'Static'}');
            });

            // Apply filters and sorting
            var doctors = allDoctors;

            if (_searchQuery.isNotEmpty) {
              doctors = doctors.where((doctor) {
                return doctor.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                    doctor.location
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    doctor.specialty
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
              }).toList();
            }

            if (_filters.containsKey('trait') && _filters['trait'] != null) {
              doctors = doctors
                  .where((doctor) => doctor.trait == _filters['trait'])
                  .toList();
            }

            if (_filters.containsKey('maxFees') && _filters['maxFees'] != null) {
              doctors = doctors
                  .where((doctor) => doctor.fees <= _filters['maxFees'])
                  .toList();
            }

            switch (_sortOption) {
              case 'Most Recommended':
                doctors.sort((a, b) => b.rating.compareTo(a.rating));
                break;
              case 'Price Low to High':
                doctors.sort((a, b) => a.fees.compareTo(b.fees));
                break;
              case 'Price High to Low':
                doctors.sort((a, b) => b.fees.compareTo(a.fees));
                break;
              case 'Short Waiting Time':
                doctors.sort((a, b) =>
                    a.waitingTimeMinutes.compareTo(b.waitingTimeMinutes));
                break;
            }

            if (_filteredDoctors == null) {
              _filteredDoctors = doctors.take(_pageSize).toList();
              _hasMore = doctors.length > _pageSize;
            }

            return Column(
              children: [
                Card(
                  elevation: 4,
                  margin: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search for doctor or hospital',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                              BorderSide(color: Colors.grey[300]!, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                              BorderSide(color: Colors.grey[300]!, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                              BorderSide(color: Colors.grey[300]!, width: 1),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                          ),
                          onChanged: _searchDoctors,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButtonWithIcon(
                                label: 'Sort',
                                icon: Icons.sort,
                                onPressed: _showSortDialog,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionButtonWithIcon(
                                label: 'Filter',
                                icon: Icons.filter_list,
                                onPressed: () => _showFilterDialog(allDoctors),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionButtonWithIcon(
                                label: 'Map',
                                icon: Icons.map,
                                onPressed: _showMapView,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredDoctors!.isEmpty
                      ? const Center(child: Text('No doctors found'))
                      : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    cacheExtent: 9999,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    itemCount:
                    _filteredDoctors!.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredDoctors!.length) {
                        _loadMoreDoctors(allDoctors);
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final doctor = _filteredDoctors![index];
                      print('Rendering doctor: ${doctor.name}');
                      return _buildDoctorCard(context, doctor);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtonWithIcon({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border.all(color: Colors.blue[800]!, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue[800], size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor doctor) {
    final doctorWithFallback = Doctor(
      name: doctor.name,
      specialty: doctor.specialty,
      rating: doctor.rating,
      numberOfReviews: doctor.numberOfReviews,
      trait: doctor.trait,
      location: doctor.location,
      fees: doctor.fees,
      waitingTimeMinutes: doctor.waitingTimeMinutes,
      availability: doctor.availability,
      isSponsored: doctor.isSponsored,
      imageUrl: doctor.imageUrl,
      bio: doctor.bio ??
          'Dr. ${doctor.name} is a specialist in ${doctor.specialty} with extensive experience.',
      reviews: doctor.reviews?.isNotEmpty == true
          ? doctor.reviews
          : [
        Review(
          comment: 'No reviews available yet.',
          stars: 0,
          reviewerName: 'System',
        ),
      ],
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            _createSlideRoute(
              DoctorProfilePage(
                doctor: doctorWithFallback,
                isFromVideoCall: true,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue[800]!, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: doctor.imageUrl.startsWith('assets/')
                          ? Image.asset(
                        doctor.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                          : doctor.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: doctor.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 70,
                                height: 70,
                                color: Colors.white,
                              ),
                            ),
                        errorWidget: (context, url, error) =>
                            Image.asset(
                              'assets/images/default_doctor.png',
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                      )
                          : Image.asset(
                        'assets/images/default_doctor.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      doctor.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue[800],
                                    ),
                                    child: const Icon(
                                      Icons.phone,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (doctor.isSponsored)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.yellow[600],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Sponsored',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.specialty,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                    (index) => Icon(
                                  index < doctor.rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.yellow[700],
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${doctor.numberOfReviews})',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.medical_services,
                color: Colors.blue,
                child: Text(
                  'Specialized in ${doctor.specialty}',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.location_on,
                color: Colors.green,
                child: Text(
                  doctor.location,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.attach_money,
                color: Colors.amber,
                child: Text(
                  'Fees: ${doctor.fees.toStringAsFixed(0)} EGP',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[900],
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.access_time,
                color: Colors.red,
                child: Text(
                  'Waiting Time: ${doctor.waitingTimeMinutes} Minutes',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[900],
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Available from ${doctor.availability}',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.share,
                          color: Colors.blue[500],
                          size: 30,
                        ),
                        onPressed: () {
                          Share.share(
                            'Check out Dr. ${doctor.name}, ${doctor.specialty} at ${doctor.location}',
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            _createSlideRoute(
                                BookingConfirmationPage(
                                    doctor: doctor, isVideoCall: true)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Book',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      cacheExtent: 9999,
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child: Container(height: 150, color: Colors.white),
        ),
      ),
    );
  }
}

class CustomPageTransitionsBuilder extends PageTransitionsBuilder {
  const CustomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    final bool isPopping =
        route.isCurrent && animation.status == AnimationStatus.reverse;
    final begin = isPopping ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var slideAnimation = animation.drive(slideTween);

    var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
    var fadeAnimation = animation.drive(fadeTween);

    var scaleTween = Tween<double>(begin: 0.95, end: 1.0).chain(CurveTween(curve: curve));
    var scaleAnimation = animation.drive(scaleTween);

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: SlideTransition(position: slideAnimation, child: child),
      ),
    );
  }
}