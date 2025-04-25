import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medics/screens/Home_Page/pharmacy/payment_page.dart';
import 'doctors_data.dart';
import 'dart:math';
import 'package:medics/screens/Home_Page/pharmacy/paymob_manager.dart';

class BookingConfirmationPage extends StatefulWidget {
  final Doctor doctor;

  const BookingConfirmationPage({Key? key, required this.doctor}) : super(key: key);

  @override
  _BookingConfirmationPageState createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  String? _selectedDay;
  String? _selectedTime;
  bool _isLoadingTimes = false;
  bool _isProcessingPayment = false;
  bool _isCheckingBooking = true; // To show loading while checking for existing booking
  bool _hasExistingBooking = false; // To track if user already has a booking

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
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your appointment with Dr. ${widget.doctor.name} has been successfully booked.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Check if the user has an existing booking
  Future<void> _checkExistingBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() {
        _isCheckingBooking = false;
        _hasExistingBooking = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(user.email)
          .get();

      setState(() {
        _hasExistingBooking = doc.exists;
        _isCheckingBooking = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking existing booking: $e')),
        );
      }
      setState(() {
        _isCheckingBooking = false;
        _hasExistingBooking = false;
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
        const SnackBar(content: Text('Cannot proceed: Consultation fees are not specified')),
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
                  DateTime.now().add(Duration(days: _getWeekDays().indexOf(_selectedDay!))),
                );
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(user.email)
                    .set({
                  'doctorId': widget.doctor.bio ?? 'unknown',
                  'doctorName': widget.doctor.name.isNotEmpty ? widget.doctor.name : 'Unknown Doctor',
                  'date': formattedDate,
                  'time': _selectedTime,
                  'userId': user.uid,
                  'userEmail': user.email,
                  'depositAmount': depositAmount,
                  'timestamp': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Booking confirmed with Dr. ${widget.doctor.name} on $_selectedDay at $_selectedTime. Paid deposit: ${depositAmount.toStringAsFixed(0)} EGP. Saved under ${user.email}',
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );

                Navigator.pop(context, true);
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Payment failed. Please try again.')),
                );
                Navigator.pop(context, false);
              }
            },
          ),
        ),
      );

      if (result == true && mounted) {
        await Future.delayed(const Duration(seconds: 4));
        _showSuccessDialog(context);
        // Refresh booking status after successful booking
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
    _checkExistingBooking(); // Check for existing booking
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
    final effectiveName = widget.doctor.name.isNotEmpty ? widget.doctor.name : 'Unknown Doctor';
    final effectiveSpecialty = widget.doctor.specialty.isNotEmpty ? widget.doctor.specialty : 'General Practitioner';
    final effectiveLocation = widget.doctor.location.isNotEmpty ? widget.doctor.location : 'Not specified';
    final effectiveFees = widget.doctor.fees > 0 ? widget.doctor.fees : 0.0;

    final weekDays = _getWeekDays();
    final availableTimes = _getAvailableTimes();

    print('Booking with Doctor: $effectiveName');
    print('Specialty: $effectiveSpecialty');
    print('Location: $effectiveLocation');
    print('Fees: $effectiveFees');
    print('Selected Day: $_selectedDay');
    print('Selected Time: $_selectedTime');

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
          title: const Text('Confirm Booking'),
          backgroundColor: Colors.blue[800],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.grey[200],
        body: _isCheckingBooking
            ? const Center(child: CircularProgressIndicator()) // Show loading while checking
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking with Dr. $effectiveName',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.medical_services, color: Colors.blue[800], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Specialty: $effectiveSpecialty',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.blue[800], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Location: $effectiveLocation',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.attach_money, color: Colors.blue[800], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Fees: ${effectiveFees.toStringAsFixed(0)} EGP',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.payment, color: Colors.blue[800], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Deposit (30%): ${(effectiveFees * 0.3).toStringAsFixed(0)} EGP',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_hasExistingBooking) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'You have already booked.\nFollow up on your booking from the My Activity page.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.red[800],
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Select Appointment Day',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue[800]),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Day',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedDay,
                        items: weekDays
                            .map((day) => DropdownMenuItem(
                          value: day,
                          child: Text(
                            day,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDay = value;
                            _selectedTime = null;
                            _isLoadingTimes = true;
                            Future.delayed(const Duration(milliseconds: 500), () {
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue[800]),
                        ),
                        const SizedBox(height: 12),
                        _isLoadingTimes
                            ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: 6,
                            itemBuilder: (context, index) => Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        )
                            : (availableTimes[_selectedDay]?.isEmpty ?? true)
                            ? Text(
                          'No times available for this day.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                            : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.5,
                          ),
                          itemCount: availableTimes[_selectedDay]?.length ?? 0,
                          itemBuilder: (context, index) {
                            final time = availableTimes[_selectedDay]![index];
                            final isSelected = _selectedTime == time;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTime = time;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue[800] : Colors.white,
                                  border: Border.all(color: Colors.blue[800]!),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _isProcessingPayment ? null : _handleBooking,
                            child: const Text('Confirm Booking', style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: _isProcessingPayment ? null : () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(fontSize: 16, color: Colors.blue[800]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_isProcessingPayment)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
