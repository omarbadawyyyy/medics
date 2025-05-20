import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'doctors_data.dart';
import 'booking_confirmation_page.dart';

class DoctorProfilePage extends StatefulWidget {
  final Doctor doctor;
  final bool isFromVideoCall;

  const DoctorProfilePage({
    Key? key,
    required this.doctor,
    this.isFromVideoCall = false,
  }) : super(key: key);

  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> with SingleTickerProviderStateMixin {
  List<Review> _reviews = [];
  final _reviewController = TextEditingController();
  int _selectedStars = 0;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _reviews = widget.doctor.reviews ?? [
      Review(comment: 'No reviews available yet.', stars: 0, reviewerName: 'System')
    ];

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  PageRouteBuilder _createForwardSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.fastOutSlowIn;

        var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var slideAnimation = animation.drive(slideTween);

        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
        var fadeAnimation = animation.drive(fadeTween);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 150),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    bool isBold = false,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.01,
        horizontal: 0,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: Colors.blue[800],
                        size: MediaQuery.of(context).size.width * 0.06,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue[800],
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                        ),
                      ),
                    ],
                  ),
                  if (trailingWidget != null) trailingWidget,
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  height: 1.5,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReviewDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: _buildReviewDialogContent(),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _selectedStars = 0;
        _reviewController.clear();
      });
    });
  }

  Widget _buildReviewDialogContent() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: screenWidth * 0.85,
          padding: EdgeInsets.all(screenWidth * 0.05),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[100]!, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.comment,
                    color: Colors.blue[800],
                    size: screenWidth * 0.07,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'Add Review',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _reviewController,
                  decoration: InputDecoration(
                    labelText: 'Your Review',
                    labelStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: screenWidth * 0.04,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                  maxLines: 3,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                      (index) => _buildAnimatedStar(index, screenWidth),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue[800]!, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06,
                        vertical: screenHeight * 0.015,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[800]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
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
    );
  }

  Widget _buildAnimatedStar(int index, double screenWidth) {
    bool isSelected = index < _selectedStars;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStars = index + 1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.yellow[900]! : Colors.grey[400]!,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.yellow[600]!.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ]
                : [],
          ),
          child: AnimatedScale(
            scale: isSelected ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: isSelected
                      ? [Colors.yellow[900]!, Colors.orange[700]!]
                      : [Colors.grey[400]!, Colors.grey[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              child: Icon(
                isSelected ? Icons.star : Icons.star_border,
                size: screenWidth * 0.07,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveName = widget.doctor.name.isNotEmpty ? widget.doctor.name : 'Unknown Doctor';
    final effectiveSpecialty = widget.doctor.specialty.isNotEmpty ? widget.doctor.specialty : 'General Practitioner';
    final effectiveBio = widget.doctor.bio ??
        'Dr. $effectiveName is a specialist in $effectiveSpecialty with extensive experience in patient care.';
    final effectiveLocation = widget.doctor.location.isNotEmpty ? widget.doctor.location : 'Not specified';
    final effectiveFees = widget.doctor.fees > 0 ? widget.doctor.fees : 0.0;
    final effectiveWaitingTime = widget.doctor.waitingTimeMinutes > 0 ? widget.doctor.waitingTimeMinutes : 0;
    final effectiveYearsOfExperience = 5;

    // Define default image path for assets
    const String defaultImagePath = 'assets/Doctors/default_doctor.png';

    // Function to build doctor image widget
    Widget buildDoctorImage(String imageUrl) {
      if (imageUrl.startsWith('assets/')) {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          width: MediaQuery.of(context).size.width * 0.3,
          height: MediaQuery.of(context).size.width * 0.3,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              defaultImagePath,
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.width * 0.3,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
            );
          },
        );
      } else {
        return CachedNetworkImage(
          imageUrl: imageUrl.isNotEmpty ? imageUrl : defaultImagePath,
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white),
          ),
          errorWidget: (context, url, error) => Image.asset(
            defaultImagePath,
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width * 0.3,
            height: MediaQuery.of(context).size.width * 0.3,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.grey,
                ),
              );
            },
          ),
          fit: BoxFit.cover,
          memCacheWidth: (MediaQuery.of(context).size.width * 0.3 * MediaQuery.of(context).devicePixelRatio).toInt(),
          memCacheHeight: (MediaQuery.of(context).size.width * 0.3 * MediaQuery.of(context).devicePixelRatio).toInt(),
        );
      }
    }

    return Theme(
      data: Theme.of(context).copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionsBuilder(),
            TargetPlatform.iOS: CustomPageTransitionsBuilder(),
          },
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.05,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.04,
            color: Colors.grey,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.08,
              vertical: MediaQuery.of(context).size.height * 0.015,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(effectiveName),
          backgroundColor: Colors.blue[800],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: Colors.grey[200],
        floatingActionButton: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: GestureDetector(
                onTapDown: (details) {
                  _animationController.stop();
                  setState(() {});
                },
                onTapUp: (details) {
                  _animationController.repeat(reverse: true);
                  Navigator.push(
                    context,
                    _createForwardSlideRoute(
                      BookingConfirmationPage(
                        doctor: widget.doctor,
                        isVideoCall: widget.isFromVideoCall,
                      ),
                    ),
                  );
                },
                onTapCancel: () {
                  _animationController.repeat(reverse: true);
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[800]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 10 * _pulseAnimation.value,
                        spreadRadius: 2 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: null,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    icon: AnimatedScale(
                      scale: _pulseAnimation.value,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.calendar_today, color: Colors.white),
                    ),
                    label: AnimatedScale(
                      scale: _pulseAnimation.value,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        widget.isFromVideoCall ? 'Book Video Call' : 'Book Appointment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue, Colors.grey],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.02,
              horizontal: MediaQuery.of(context).size.width * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue[800]!, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(120),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              height: MediaQuery.of(context).size.width * 0.3,
                              child: buildDoctorImage(widget.doctor.imageUrl),
                            ),
                          ),
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      effectiveName,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontSize: MediaQuery.of(context).size.width * 0.06,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.share,
                                      color: Colors.blue[800],
                                      size: MediaQuery.of(context).size.width * 0.07,
                                    ),
                                    onPressed: () {
                                      Share.share(
                                        'Check out $effectiveName, $effectiveSpecialty at $effectiveLocation. Book now: https://example.com/doctor/${widget.doctor.bio}',
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
                              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(
                                      5,
                                          (index) => Icon(
                                        index < widget.doctor.rating.floor() ? Icons.star : Icons.star_border,
                                        color: Colors.yellow[700],
                                        size: MediaQuery.of(context).size.width * 0.055,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                                  Text(
                                    '(${widget.doctor.numberOfReviews})',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                              Text(
                                'Trait: ${widget.doctor.trait}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.doctor.isSponsored)
                                Padding(
                                  padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
                                  child: const Text(
                                    'Sponsored',
                                    style: TextStyle(
                                      color: Colors.blue,
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                _buildInfoSection(
                  icon: Icons.info,
                  title: 'About',
                  content: effectiveBio,
                ),
                _buildInfoSection(
                  icon: Icons.location_on,
                  title: 'Location',
                  content: effectiveLocation,
                ),
                _buildInfoSection(
                  icon: Icons.attach_money,
                  title: 'Fees',
                  content: '${effectiveFees.toStringAsFixed(0)} EGP',
                  isBold: true,
                ),
                _buildInfoSection(
                  icon: Icons.access_time,
                  title: 'Waiting Time',
                  content: '$effectiveWaitingTime Minutes',
                  isBold: true,
                ),
                _buildInfoSection(
                  icon: Icons.work,
                  title: 'Experience',
                  content: '$effectiveYearsOfExperience Years',
                  isBold: true,
                ),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  margin: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.01,
                    horizontal: 0,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.comment,
                                  color: Colors.blue,
                                  size: MediaQuery.of(context).size.width * 0.06,
                                ),
                                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
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
                        SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                        _reviews.isEmpty
                            ? Text(
                          'No reviews available.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          cacheExtent: 9999,
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).size.height * 0.02,
                              ),
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
                                            size: MediaQuery.of(context).size.width * 0.045,
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
                _buildInfoSection(
                  icon: Icons.question_answer,
                  title: 'FAQs',
                  content: '''
• Does $effectiveName accept insurance? Yes, most major insurances are accepted.
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

class CustomPageTransitionsBuilder extends PageTransitionsBuilder {
  const CustomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final bool isPopping = route.isCurrent && animation.status == AnimationStatus.reverse;
    final begin = isPopping ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.fastOutSlowIn;

    var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var slideAnimation = animation.drive(slideTween);

    var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
    var fadeAnimation = animation.drive(fadeTween);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }
}