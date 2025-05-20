import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../search/booking_confirmation_page.dart';
import '../search/doctors_data.dart';

class DoctorVisitPage extends StatelessWidget {
  final String email;
  final Map<String, dynamic> selectedAddress;
  final String specialty;

  const DoctorVisitPage({
    required this.email,
    required this.selectedAddress,
    required this.specialty,
  });

  void _navigateBackToAddressManagement(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
        title: Text(
          specialty,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.white70),
            onPressed: () => _navigateBackToAddressManagement(context),
            tooltip: 'Change Address',
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1976D2), // Blue[700]
                Color(0xFF0D47A1), // Blue[900]
              ],
            ),
          ),
        ),
        elevation: 6,
        shadowColor: Colors.black54,
        titleSpacing: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .where('specialty', isEqualTo: specialty)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.red),
                  SizedBox(height: 10),
                  Text(
                    'Error loading doctors',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                itemCount: 3,
                itemBuilder: (context, index) => Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                  child: Container(
                    height: 200,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }

          // Map Firestore doctors
          final firestoreDoctors = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Doctor(
              name: data['name'] ?? 'Unknown Doctor',
              specialty: data['specialty'] ?? specialty,
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

          // Get static doctors from DoctorsData
          final staticDoctors = DoctorsData.doctors
              .where((doctor) => doctor.specialty == specialty)
              .toList();

          // Combine and remove duplicates
          final allDoctorsMap = <String, Doctor>{};
          for (var doctor in [...staticDoctors, ...firestoreDoctors]) {
            allDoctorsMap['${doctor.name}_${doctor.specialty}'] = doctor;
          }
          final filteredDoctors = allDoctorsMap.values.toList();

          if (filteredDoctors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No doctors available for $specialty',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try another specialty or address',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _navigateBackToAddressManagement(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF1976D2)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Change Address',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            itemCount: filteredDoctors.length,
            itemBuilder: (context, index) {
              final doctor = filteredDoctors[index];
              return _buildHomeVisitDoctorCard(context, doctor);
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeVisitDoctorCard(BuildContext context, Doctor doctor) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        child: InkWell(
          onTap: () {
            // يمكن إضافة تفاصيل الدكتور هنا إذا أردت
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: doctor.imageUrl.startsWith('assets/')
                          ? Image.asset(
                        doctor.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                          : CachedNetworkImage(
                        imageUrl: doctor.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 70,
                            height: 70,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
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
                          Text(
                            doctor.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            doctor.trait,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_city,
                                color: Colors.blue[700],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                selectedAddress['governorate'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                            (index) => Icon(
                          index < doctor.rating.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber[600],
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${doctor.numberOfReviews})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.blue[700],
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.fees.toStringAsFixed(0)} EGP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.blue[700],
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.waitingTimeMinutes} min',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                              BookingConfirmationPage(doctor: doctor),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;
                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(
                                position: offsetAnimation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.book_online, size: 18,color: Colors.white,),
                    label: const Text(
                      'Book Visit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}