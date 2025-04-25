import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'doctors_data.dart';
import 'doctor_profile_page.dart';
import 'booking_confirmation_page.dart';

class SpecialtyPage extends StatefulWidget {
  final String specialty;

  const SpecialtyPage({Key? key, required this.specialty}) : super(key: key);

  @override
  _SpecialtyPageState createState() => _SpecialtyPageState();
}

class _SpecialtyPageState extends State<SpecialtyPage> {
  List<Doctor>? _filteredDoctors;
  String _searchQuery = '';
  String _sortOption = 'Rating';
  Map<String, dynamic> _filters = {};
  bool _isLoading = true;
  int _pageSize = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    // Debug print to check doctors data
    print('Doctors count: ${DoctorsData.doctors.length}');
    for (var doctor in DoctorsData.doctors) {
      print('Doctor: ${doctor.name}, Bio: ${doctor.bio}, Reviews: ${doctor.reviews?.length ?? 0}');
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _filteredDoctors = null;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _filteredDoctors = DoctorsData.doctors
          .where((doctor) => doctor.specialty == widget.specialty)
          .take(_pageSize)
          .toList();
      _isLoading = false;
      _hasMore = DoctorsData.doctors
          .where((doctor) => doctor.specialty == widget.specialty)
          .length >
          _pageSize;
    });
  }

  Future<void> _loadMoreDoctors() async {
    if (!_hasMore || _isLoading || _filteredDoctors == null) return;
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      final nextDoctors = DoctorsData.doctors
          .where((doctor) => doctor.specialty == widget.specialty)
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

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters;
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    var doctors = DoctorsData.doctors
        .where((doctor) => doctor.specialty == widget.specialty)
        .toList();

    if (_searchQuery.isNotEmpty) {
      doctors = doctors.where((doctor) {
        return doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            doctor.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            doctor.specialty.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_filters.containsKey('trait') && _filters['trait'] != null) {
      doctors =
          doctors.where((doctor) => doctor.trait == _filters['trait']).toList();
    }

    if (_filters.containsKey('maxFees') && _filters['maxFees'] != null) {
      doctors = doctors
          .where((doctor) => doctor.fees <= _filters['maxFees'])
          .toList();
    }

    switch (_sortOption) {
      case 'Rating':
        doctors.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Fees':
        doctors.sort((a, b) => a.fees.compareTo(b.fees));
        break;
      case 'Waiting Time':
        doctors.sort(
                (a, b) => a.waitingTimeMinutes.compareTo(b.waitingTimeMinutes));
        break;
    }

    setState(() {
      _filteredDoctors = doctors.take(_pageSize).toList();
      _hasMore = doctors.length > _pageSize;
    });
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Rating'),
              onTap: () {
                _sortDoctors('Rating');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Fees'),
              onTap: () {
                _sortDoctors('Fees');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Waiting Time'),
              onTap: () {
                _sortDoctors('Waiting Time');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final maxFeesController = TextEditingController();
    String? selectedTrait;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Trait'),
              items: DoctorsData.doctors
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
            TextField(
              controller: maxFeesController,
              decoration: const InputDecoration(labelText: 'Max Fees (EGP)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final filters = <String, dynamic>{};
              if (selectedTrait != null) {
                filters['trait'] = selectedTrait;
              }
              if (maxFeesController.text.isNotEmpty) {
                try {
                  filters['maxFees'] = double.parse(maxFeesController.text);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid number for fees')),
                  );
                  return;
                }
              }
              _applyFilters(filters);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showMapView() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map View'),
        content:
        const Text('Temporary placeholder for map. To be updated later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  PageRouteBuilder _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.specialty} Doctors'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
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
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                          onPressed: _showFilterDialog,
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
            child: _isLoading && _filteredDoctors == null
                ? _buildLoadingState()
                : _filteredDoctors == null
                ? const Center(child: CircularProgressIndicator())
                : _filteredDoctors!.isEmpty
                ? const Center(child: Text('No doctors found'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              itemCount: _filteredDoctors!.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _filteredDoctors!.length) {
                  _loadMoreDoctors();
                  return const Center(child: CircularProgressIndicator());
                }
                final doctor = _filteredDoctors![index];
                return _buildDoctorCard(context, doctor);
              },
            ),
          ),
        ],
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
    // Fallback for bio and reviews
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
            _createSlideRoute(DoctorProfilePage(doctor: doctorWithFallback)),
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
                      child: const SizedBox(
                        width: 70,
                        height: 70,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        ),
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
                                BookingConfirmationPage(doctor: doctor)),
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

  Widget _buildInfoRow(
      {required IconData icon, required Color color, required Widget child}) {
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