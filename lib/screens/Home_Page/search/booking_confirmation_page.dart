import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medics/screens/Home_Page/pharmacy/payment_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'doctors_data.dart';
import 'dart:math';
import 'package:medics/screens/Home_Page/pharmacy/paymob_manager.dart';
import 'package:uuid/uuid.dart';

class BookingConfirmationPage extends StatefulWidget {
  final Doctor doctor;
  final bool isVideoCall;

  const BookingConfirmationPage({
    Key? key,
    required this.doctor,
    this.isVideoCall = false,
  }) : super(key: key);

  @override
  _BookingConfirmationPageState createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  String? _selectedDay;
  String? _selectedTime;
  bool _isLoadingTimes = false;
  bool _isProcessingPayment = false;
  bool _isCheckingBooking = true;
  int _existingBookingsCount = 0;

  static const List<String> _daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  static const List<String> _monthsOfYear = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<String> _getWeekDays() {
    List<String> days = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      DateTime day = now.add(Duration(days: i));
      String formattedDay =
          '${_daysOfWeek[day.weekday % 7]}, ${_monthsOfYear[day.month - 1]} ${day.day}';
      days.add(formattedDay);
    }
    return days;
  }

  Map<String, List<String>> _getAvailableTimes() {
    Random random = Random(widget.doctor.name.hashCode);
    List<String> baseTimes = [
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '1:00 PM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
    ];
    Map<String, List<String>> availableTimes = {};
    for (String day in _getWeekDays()) {
      int count = random.nextInt(4) + 2;
      Set<String> timesSet = {};
      while (timesSet.length < count && timesSet.length < baseTimes.length) {
        timesSet.add(baseTimes[random.nextInt(baseTimes.length)]);
      }
      List<String> times = timesSet.toList()..sort();
      availableTimes[day] = times;
    }
    return availableTimes;
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
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  String _formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _showSuccessDialog(BuildContext context) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green[600],
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isVideoCall ? 'Video Call Confirmed!' : 'Booking Confirmed!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isVideoCall
                  ? 'Your video call with ${widget.doctor.name} has been successfully booked.'
                  : 'Your appointment with ${widget.doctor.name} has been successfully booked.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.pop(context); // Return to previous screen
            },
            child: Text(
              'OK',
              style: TextStyle(color: Colors.blue[800], fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkExistingBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() {
        _isCheckingBooking = false;
        _existingBookingsCount = 0;
      });
      return;
    }

    try {
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(user.email)
          .collection('userBookings')
          .get();

      setState(() {
        _existingBookingsCount = bookingsSnapshot.docs.length;
        _isCheckingBooking = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking existing bookings: $e')),
        );
      }
      setState(() {
        _isCheckingBooking = false;
        _existingBookingsCount = 0;
      });
    }
  }

  void _handleBooking() async {
    if (_selectedDay == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a day and time')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book an appointment')),
      );
      return;
    }

    final effectiveFees = widget.doctor.fees > 0 ? widget.doctor.fees : 0.0;
    if (effectiveFees == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot proceed: Consultation fees are not specified')),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final depositAmount = effectiveFees * 0.3;
      final paymobManager = PaymobManager();
      final paymentKey = await paymobManager.getPaymentKey(depositAmount);

      final scaffoldMessenger = ScaffoldMessenger.of(context);

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            totalAmount: depositAmount,
            paymentKey: paymentKey,
            onPaymentComplete: (success) async {
              if (success) {
                final formattedDate = _formatDate(
                  DateTime.now()
                      .add(Duration(days: _getWeekDays().indexOf(_selectedDay!))),
                );
                final bookingId = const Uuid().v4();
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(user.email)
                    .collection('userBookings')
                    .doc(bookingId)
                    .set({
                  'bookingId': bookingId,
                  'doctorId': widget.doctor.bio ?? 'unknown',
                  'doctorName': widget.doctor.name.isNotEmpty
                      ? widget.doctor.name
                      : 'Unknown Doctor',
                  'date': formattedDate,
                  'time': _selectedTime,
                  'userId': user.uid,
                  'userEmail': user.email,
                  'depositAmount': depositAmount,
                  'isVideoCall': widget.isVideoCall,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isVideoCall
                          ? 'Video call confirmed with ${widget.doctor.name} on $_selectedDay at $_selectedTime. Paid deposit: ${depositAmount.toStringAsFixed(0)} EGP.'
                          : 'Booking confirmed with ${widget.doctor.name} on $_selectedDay at $_selectedTime. Paid deposit: ${depositAmount.toStringAsFixed(0)} EGP.',
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );

                Navigator.pop(context, true);
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                      content: Text('Payment failed. Please try again.')),
                );
                Navigator.pop(context, false);
              }
            },
          ),
        ),
      );

      if (result == true && mounted) {
        _showSuccessDialog(context);
        await _checkExistingBooking();
      } else if (result == null && mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Payment process was interrupted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkExistingBooking();
    _selectedDay = _getWeekDays().first;
    _isLoadingTimes = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoadingTimes = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveName = widget.doctor.name.isNotEmpty
        ? widget.doctor.name
        : 'Unknown Doctor';
    final effectiveSpecialty = widget.doctor.specialty.isNotEmpty
        ? widget.doctor.specialty
        : 'General Practitioner';
    final effectiveLocation = widget.doctor.location.isNotEmpty
        ? widget.doctor.location
        : 'Not specified';
    final effectiveFees = widget.doctor.fees > 0 ? widget.doctor.fees : 0.0;

    final nameContainsDoctorTitle =
        effectiveName.toLowerCase().contains('dr.') ||
            effectiveName.contains('دكتور');
    final displayName = nameContainsDoctorTitle ? effectiveName : 'Dr. $effectiveName';

    final weekDays = _getWeekDays();
    final availableTimes = _getAvailableTimes();

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue[800],
            side: BorderSide(color: Colors.blue[800]!, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[600]),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isVideoCall ? 'Confirm Video Call' : 'Confirm Booking',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.blue[800],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.grey[200],
        body: _isCheckingBooking
            ? Center(
          child: CircularProgressIndicator(color: Colors.blue[800]),
        )
            : Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[50]!, Colors.grey[200]!],
            ),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isVideoCall
                                  ? 'Video Call with $displayName'
                                  : 'Booking with $displayName',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 24),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: Icon(Icons.medical_services,
                                  color: Colors.blue[800], size: 24),
                              title: Text(
                                'Specialty: $effectiveSpecialty',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[800]),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            ListTile(
                              leading: Icon(
                                  widget.isVideoCall
                                      ? Icons.videocam
                                      : Icons.person,
                                  color: Colors.blue[800],
                                  size: 24),
                              title: Text(
                                'Type: ${widget.isVideoCall ? 'Video Call' : 'In-Person Appointment'}',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[800]),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            ListTile(
                              leading: Icon(Icons.location_on,
                                  color: Colors.blue[800], size: 24),
                              title: Text(
                                'Location: $effectiveLocation',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[800]),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            ListTile(
                              leading: Icon(Icons.attach_money,
                                  color: Colors.blue[800], size: 24),
                              title: Text(
                                'Fees: ${effectiveFees.toStringAsFixed(0)} EGP',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[900],
                                    fontWeight: FontWeight.bold),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            ListTile(
                              leading: Icon(Icons.payment,
                                  color: Colors.blue[800], size: 24),
                              title: Text(
                                'Deposit (30%): ${(effectiveFees * 0.3).toStringAsFixed(0)} EGP',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[900],
                                    fontWeight: FontWeight.bold),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Select Appointment Day',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.blue[800]),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Day',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      value: _selectedDay,
                      items: weekDays
                          .map((day) => DropdownMenuItem(
                        value: day,
                        child: Text(
                          day,
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16),
                        ),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value;
                          _selectedTime = null;
                          _isLoadingTimes = true;
                          Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                if (mounted) {
                                  setState(() {
                                    _isLoadingTimes = false;
                                  });
                                }
                              });
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_selectedDay != null) ...[
                      Text(
                        'Available Times',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.blue[800]),
                      ),
                      const SizedBox(height: 12),
                      _isLoadingTimes
                          ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics:
                          const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.5,
                          ),
                          itemCount: 6,
                          itemBuilder: (context, index) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      )
                          : (availableTimes[_selectedDay]?.isEmpty ?? true)
                          ? Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16),
                        child: Text(
                          'No times available for this day.',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600]),
                        ),
                      )
                          : GridView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.5,
                        ),
                        itemCount:
                        availableTimes[_selectedDay]?.length ??
                            0,
                        itemBuilder: (context, index) {
                          final time =
                          availableTimes[_selectedDay]![index];
                          final isSelected = _selectedTime == time;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTime = time;
                              });
                            },
                            borderRadius:
                            BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue[800]
                                    : Colors.white,
                                border: Border.all(
                                    color: Colors.blue[800]!,
                                    width: isSelected ? 2 : 1),
                                borderRadius:
                                BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey
                                        .withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                time,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.blue[800],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(
                            duration: 400.ms,
                            delay: (index * 100).ms,
                          ).slideY(
                            begin: -0.3,
                            end: 0,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isProcessingPayment
                                ? null
                                : _handleBooking,
                            child: Text(
                              widget.isVideoCall
                                  ? 'Confirm Video Call'
                                  : 'Confirm Booking',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isProcessingPayment
                                ? null
                                : () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800]),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(
                begin: -0.3,
                end: 0,
                duration: 400.ms,
              ),
              if (_isProcessingPayment)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.blue[800]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}