import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'doctors_data.dart';
import 'booking_confirmation_page.dart';

class DoctorProfilePage extends StatefulWidget {
  final Doctor doctor;

  const DoctorProfilePage({Key? key, required this.doctor}) : super(key: key);

  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  List<Review> _reviews = [];
  final _reviewController = TextEditingController();
  int _selectedStars = 0;

  @override
  void initState() {
    super.initState();
    _reviews = widget.doctor.reviews ?? [
      Review(comment: 'No reviews available yet.', stars: 0, reviewerName: 'System')
    ];
  }

  // Slide transition route
  PageRouteBuilder _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Widget for info section
  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    bool isBold = false,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.blue[800], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  if (trailingWidget != null) trailingWidget,
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show dialog to add a review
  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  labelText: 'Your Review',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                      (index) => IconButton(
                    icon: Icon(
                      index < _selectedStars ? Icons.star : Icons.star_border,
                      color: Colors.yellow[700],
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedStars = index + 1;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_reviewController.text.isNotEmpty && _selectedStars > 0) {
                  setState(() {
                    _reviews.insert(
                      0,
                      Review(
                        comment: _reviewController.text,
                        stars: _selectedStars,
                        reviewerName: 'Current User',
                      ),
                    );
                    _reviewController.clear();
                    _selectedStars = 0;
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _selectedStars = 0;
        _reviewController.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fallback for data
    final effectiveName = widget.doctor.name.isNotEmpty ? widget.doctor.name : 'Unknown Doctor';
    final effectiveSpecialty = widget.doctor.specialty.isNotEmpty ? widget.doctor.specialty : 'General Practitioner';
    final effectiveBio = widget.doctor.bio ??
        'Dr. $effectiveName is a specialist in $effectiveSpecialty with extensive experience in patient care.';
    final effectiveLocation = widget.doctor.location.isNotEmpty ? widget.doctor.location : 'Not specified';
    final effectiveFees = widget.doctor.fees > 0 ? widget.doctor.fees : 0.0;
    final effectiveWaitingTime = widget.doctor.waitingTimeMinutes > 0 ? widget.doctor.waitingTimeMinutes : 0;
    final effectiveYearsOfExperience = 5; // Fallback since field is not in Doctor class

    // Debug print
    print('Doctor: $effectiveName');
    print('Specialty: $effectiveSpecialty');
    print('Location: $effectiveLocation');
    print('Fees: $effectiveFees');
    print('Waiting Time: $effectiveWaitingTime');
    print('Years of Experience: $effectiveYearsOfExperience');

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Dr. $effectiveName'),
          backgroundColor: Colors.blue[800],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.grey[200],
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              _createSlideRoute(BookingConfirmationPage(doctor: widget.doctor)),
            );
          },
          backgroundColor: Colors.blue[800],
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          label: const Text('Book Appointment', style: TextStyle(color: Colors.white)),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[50]!, Colors.grey[200]!],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue[800]!, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(120),
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: widget.doctor.imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl: widget.doctor.imageUrl,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(color: Colors.white),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                fit: BoxFit.cover,
                              )
                                  : const Icon(
                                Icons.person,
                                size: 80,
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
                                      'Dr. $effectiveName',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.share, color: Colors.blue[800], size: 28),
                                    onPressed: () {
                                      Share.share(
                                        'Check out Dr. $effectiveName, $effectiveSpecialty at $effectiveLocation. Book now: https://example.com/doctor/${widget.doctor.bio}',
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                effectiveSpecialty,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(
                                      5,
                                          (index) => Icon(
                                        index < widget.doctor.rating.floor() ? Icons.star : Icons.star_border,
                                        color: Colors.yellow[700],
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${widget.doctor.numberOfReviews})',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Trait: ${widget.doctor.trait}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.doctor.isSponsored)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Sponsored',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // About Section
                _buildInfoSection(
                  icon: Icons.info,
                  title: 'About',
                  content: effectiveBio,
                ),
                // Location Section
                _buildInfoSection(
                  icon: Icons.location_on,
                  title: 'Location',
                  content: effectiveLocation,
                ),
                // Fees Section
                _buildInfoSection(
                  icon: Icons.attach_money,
                  title: 'Fees',
                  content: '${effectiveFees.toStringAsFixed(0)} EGP',
                  isBold: true,
                ),
                // Waiting Time Section
                _buildInfoSection(
                  icon: Icons.access_time,
                  title: 'Waiting Time',
                  content: '$effectiveWaitingTime Minutes',
                  isBold: true,
                ),
                // Years of Experience
                _buildInfoSection(
                  icon: Icons.work,
                  title: 'Experience',
                  content: '$effectiveYearsOfExperience Years',
                  isBold: true,
                ),
                // Reviews Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.comment, color: Colors.blue[800], size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Reviews',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _showAddReviewDialog,
                              child: const Text('Add Review'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _reviews.isEmpty
                            ? Text(
                          'No reviews available.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          review.reviewerName,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          5,
                                              (starIndex) => Icon(
                                            starIndex < review.stars ? Icons.star : Icons.star_border,
                                            color: Colors.yellow[700],
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    review.comment,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // FAQs Section
                _buildInfoSection(
                  icon: Icons.question_answer,
                  title: 'FAQs',
                  content: '''
• Does Dr. $effectiveName accept insurance? Yes, most major insurances are accepted.
• What are the clinic hours? Mon-Fri, 9 AM - 7 PM.
• Is teleconsultation available? Yes, upon request.
                  ''',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}