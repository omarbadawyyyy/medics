import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medics/screens/Home_Page/doctor_call/video_call_screen.dart';
import 'package:medics/screens/login/login_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'SettingsPage.dart';

class DoctorDashboard extends StatefulWidget {
  final String email;
  final String name;
  final String phone;
  final String? imagePath;
  final String doctorEmail;

  const DoctorDashboard({
    super.key,
    required this.email,
    required this.name,
    required this.phone,
    this.imagePath,
    required this.doctorEmail,
  });

  static const String agoraAppId = '286f325dbb1349ea99178d2e8fed6217';

  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late RtcEngine _engine;
  bool _isEngineInitialized = false;
  bool _isApproving = false;
  bool _isStartingCall = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isImageLoading = true;
  final Map<String, bool> _isUploadingPrescription = {};
  final Map<String, bool> _isDeletingPrescription = {};
  final Map<String, bool> _isFinishingBooking = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('DoctorDashboard initialized with name: ${widget.name}, email: ${widget.doctorEmail}');
    if (widget.name.isEmpty) {
      print('Error: Doctor name is empty! Please provide a valid name.');
    }
    _initAgora();
  }

  Future<String?> _fetchDoctorImage() async {
    print('Starting to fetch doctor image for email: ${widget.doctorEmail}');
    try {
      print('Querying Firestore for doctor document with email: ${widget.doctorEmail}');
      DocumentSnapshot doctorDoc = await _firestore
          .collection('doctors')
          .doc(widget.doctorEmail)
          .get(const GetOptions(source: Source.serverAndCache));

      if (doctorDoc.exists && doctorDoc.data() != null) {
        print('Doctor document found in Firestore, checking data...');
        Map<String, dynamic> data = doctorDoc.data() as Map<String, dynamic>;
        if (data.containsKey('imageBase64') && data['imageBase64'] != null) {
          String imageBase64 = data['imageBase64'] as String;
          print('Base64 image retrieved');
          return imageBase64;
        } else {
          print('No valid imageBase64 found in Firestore document: ${data.toString()}');
          return null;
        }
      } else {
        print('Doctor document does not exist in Firestore for email: ${widget.doctorEmail}');
        return null;
      }
    } catch (e) {
      print('Error fetching doctor image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _uploadDoctorImage() async {
    try {
      final picker = ImagePicker();
      // First, pick the image to check its size
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final bytes = await File(pickedFile.path).readAsBytes();
      // Check if image size exceeds 5MB
      if (bytes.length > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image size too large. Please select an image smaller than 5MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String base64Image;
      // If image size is larger than 1MB, compress it
      if (bytes.length > 1024 * 1024) {
        print('Image size exceeds 1MB, compressing...');
        // Pick again with compression
        final compressedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85, // Compress to maintain good quality
        );
        if (compressedFile == null) return;

        final compressedBytes = await File(compressedFile.path).readAsBytes();
        // Check if compressed image is still too large
        if (compressedBytes.length > 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compressed image still too large. Please select a smaller image.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        base64Image = base64Encode(compressedBytes);
      } else {
        // Use original image if size is <= 1MB
        base64Image = base64Encode(bytes);
      }

      await _firestore.collection('doctors').doc(widget.doctorEmail).set(
        {'imageBase64': base64Image},
        SetOptions(merge: true),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      setState(() {
        _isImageLoading = false;
      });
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadPrescriptionImage(String bookingId, String userEmail) async {
    if (_isUploadingPrescription[bookingId] == true) return;

    setState(() {
      _isUploadingPrescription[bookingId] = true;
    });
    try {
      final picker = ImagePicker();
      // First, pick the image to check its size
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final bytes = await File(pickedFile.path).readAsBytes();
      // Check if image size exceeds 5MB
      if (bytes.length > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription image too large. Please select an image smaller than 5MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String base64Image;
      // If image size is larger than 1MB, compress it
      if (bytes.length > 1024 * 1024) {
        print('Prescription image size exceeds 1MB, compressing...');
        // Pick again with compression
        final compressedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85, // Compress to maintain good quality
        );
        if (compressedFile == null) return;

        final compressedBytes = await File(compressedFile.path).readAsBytes();
        // Check if compressed image is still too large
        if (compressedBytes.length > 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compressed prescription image still too large. Please select a smaller image.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        base64Image = base64Encode(compressedBytes);
      } else {
        // Use original image if size is <= 1MB
        base64Image = base64Encode(bytes);
      }

      await _firestore
          .collection('bookings')
          .doc(userEmail)
          .collection('userBookings')
          .doc(bookingId)
          .update({
        'prescriptionImage': base64Image,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription image uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading prescription image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading prescription image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingPrescription[bookingId] = false;
      });
    }
  }

  Future<void> _deletePrescriptionImage(String bookingId, String userEmail) async {
    if (_isDeletingPrescription[bookingId] == true) return;

    setState(() {
      _isDeletingPrescription[bookingId] = true;
    });
    try {
      await _firestore
          .collection('bookings')
          .doc(userEmail)
          .collection('userBookings')
          .doc(bookingId)
          .update({
        'prescriptionImage': FieldValue.delete(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription image deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting prescription image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting prescription image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isDeletingPrescription[bookingId] = false;
      });
    }
  }

  Future<void> _finishBooking(String bookingId, String userEmail) async {
    if (_isFinishingBooking[bookingId] == true) return;

    setState(() {
      _isFinishingBooking[bookingId] = true;
    });
    try {
      await _firestore
          .collection('bookings')
          .doc(userEmail)
          .collection('userBookings')
          .doc(bookingId)
          .update({
        'status': 'finished',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking finished successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error finishing booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finishing booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isFinishingBooking[bookingId] = false;
      });
    }
  }

  @override
  void dispose() {
    print('Disposing DoctorDashboard, stopping preview, leaving channel, and releasing engine');
    if (_isEngineInitialized) {
      try {
        _engine.stopPreview();
        _engine.leaveChannel();
        _engine.release();
      } catch (e) {
        print('Error cleaning up Agora engine: $e');
      }
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state changed: $state');
    if (state == AppLifecycleState.resumed) {
      print('App resumed, triggering refresh');
      _refreshPage();
    } else if (state == AppLifecycleState.detached) {
      print('App detached, triggering refresh');
      _refreshPage();
    }
  }

  Future<bool> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _initAgora() async {
    try {
      print('Requesting camera and microphone permissions...');
      var status = await [Permission.camera, Permission.microphone].request();
      if (status[Permission.camera]!.isDenied || status[Permission.microphone]!.isDenied) {
        print('Camera or microphone permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera and microphone permissions are required for video calls'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('Initializing Agora engine with App ID: ${DoctorDashboard.agoraAppId}');
      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: DoctorDashboard.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('Joined channel: ${connection.channelId}, uid: ${connection.localUid}');
            setState(() {
              _isEngineInitialized = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('Remote user $remoteUid joined channel: ${connection.channelId}');
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('Remote user $remoteUid offline, reason: $reason');
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora error: Code $err, message: $msg');
            String errorMessage;
            switch (err) {
              case ErrorCodeType.errInvalidAppId:
                errorMessage = 'Invalid App ID. Please check your Agora App ID.';
                break;
              case ErrorCodeType.errInvalidChannelName:
                errorMessage = 'Invalid channel name. Please check the channel name.';
                break;
              case ErrorCodeType.errTokenExpired:
                errorMessage = 'Token expired. Please generate a new token.';
                break;
              case ErrorCodeType.errInvalidToken:
                errorMessage = 'Invalid token. Please check your token.';
                break;
              case ErrorCodeType.errJoinChannelRejected:
                errorMessage = 'Failed to join channel. Please try again.';
                break;
              default:
                errorMessage = 'Agora error: $msg (Code: $err)';
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );

      await _engine.setCameraCapturerConfiguration(
        const CameraCapturerConfiguration(
          cameraDirection: CameraDirection.cameraFront,
          format: VideoFormat(width: 320, height: 240, fps: 15),
        ),
      );

      print('Agora engine initialized successfully without enabling video');
      setState(() {
        _isEngineInitialized = true;
      });
    } catch (e) {
      print('Error initializing Agora: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing video call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startVideoCall(String bookingId, String userEmail) async {
    if (_isStartingCall || !_isEngineInitialized) {
      print('Video call in progress or engine not initialized');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video call service is not ready. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isStartingCall = true);
    try {
      String channelName = 'medics-${bookingId.replaceAll('-', '')}';
      print('Starting video call for booking: $bookingId, user: $userEmail, channel: $channelName');

      print('Enabling video and starting preview...');
      await _engine.enableVideo();
      await _engine.startPreview();

      await _firestore
          .collection('bookings')
          .doc(userEmail)
          .collection('userBookings')
          .doc(bookingId)
          .update({
        'videoCallLink': channelName,
        'callStatus': 'pending',
      });

      String sanitizedChannelName = channelName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
      if (sanitizedChannelName.isEmpty || sanitizedChannelName.length > 64) {
        throw Exception('Invalid channel name: $sanitizedChannelName');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              channelName: sanitizedChannelName,
              engine: _engine,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error starting video call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting video call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isStartingCall = false);
    }
  }

  Future<void> _approveBooking(String bookingId, String userEmail) async {
    if (_isApproving) return;

    setState(() => _isApproving = true);
    try {
      print('Approving booking: $bookingId for user: $userEmail');
      await _firestore
          .collection('bookings')
          .doc(userEmail)
          .collection('userBookings')
          .doc(bookingId)
          .update({
        'doctorApproval': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error approving booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isApproving = false);
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          _createSlideRoute(),
        );
      }
    } catch (e) {
      print('Error logging out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  PageRouteBuilder _createSlideRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  Future<void> _refreshPage() async {
    try {
      print('Refreshing page for doctor: ${widget.name}');
      bool isConnected = await _checkInternetConnection();
      if (!isConnected) {
        print('No internet connection detected');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No internet connection. Please check your network and try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (_isEngineInitialized) {
        print('Cleaning up Agora engine');
        try {
          await _engine.stopPreview();
          await _engine.leaveChannel();
          await _engine.release();
        } catch (e) {
          print('Error cleaning up Agora engine: $e');
        }
        setState(() {
          _isEngineInitialized = false;
        });
      }

      await _initAgora();

      try {
        await _firestore.collection('bookings').get(const GetOptions(source: Source.server));
      } catch (e) {
        print('Error fetching bookings from Firestore: $e');
        throw Exception('Failed to fetch bookings: $e');
      }

      setState(() {
        _isApproving = false;
        _isStartingCall = false;
        _isUploadingPrescription.clear();
        _isDeletingPrescription.clear();
        _isFinishingBooking.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Page refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error refreshing page: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing page: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchDoctorBookings() async* {
    print('Fetching bookings for doctor name: ${widget.name} (email: ${widget.doctorEmail})');
    try {
      bool isConnected = await _checkInternetConnection();
      if (!isConnected) {
        print('No internet connection for fetching bookings');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No internet connection. Showing cached data if available.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        QuerySnapshot usersSnapshot = await _firestore.collection('bookings').get(const GetOptions(source: Source.cache));
        List<Map<String, dynamic>> allBookings = [];

        for (var userDoc in usersSnapshot.docs) {
          String userEmail = userDoc.id;
          QuerySnapshot bookingsSnapshot = await _firestore
              .collection('bookings')
              .doc(userEmail)
              .collection('userBookings')
              .get(const GetOptions(source: Source.cache));

          for (var bookingDoc in bookingsSnapshot.docs) {
            Map<String, dynamic> bookingData = bookingDoc.data() as Map<String, dynamic>;
            String bookingDoctorName = (bookingData['doctorName']?.toString() ?? '')
                .toLowerCase()
                .replaceAll('dr.', '')
                .replaceAll('dr', '')
                .trim();
            String widgetDoctorName = widget.name
                .toLowerCase()
                .replaceAll('dr.', '')
                .replaceAll('dr', '')
                .trim();
            bool isVideoCall = bookingData['isVideoCall'] ?? false;

            String bookingDoctorFirstName = bookingDoctorName.split(' ').first;
            bool isDoctorMatch = bookingDoctorFirstName == widgetDoctorName || bookingDoctorName.contains(widgetDoctorName);
            bool shouldAddBooking = isDoctorMatch || isVideoCall;

            if (shouldAddBooking) {
              bookingData['bookingId'] = bookingDoc.id;
              bookingData['userEmail'] = userEmail;
              allBookings.add(bookingData);
            }
          }
        }

        yield allBookings;
        return;
      }

      QuerySnapshot usersSnapshot = await _firestore.collection('bookings').get(const GetOptions(source: Source.server));
      List<Map<String, dynamic>> allBookings = [];

      for (var userDoc in usersSnapshot.docs) {
        String userEmail = userDoc.id;
        QuerySnapshot bookingsSnapshot = await _firestore
            .collection('bookings')
            .doc(userEmail)
            .collection('userBookings')
            .get(const GetOptions(source: Source.server));

        for (var bookingDoc in bookingsSnapshot.docs) {
          Map<String, dynamic> bookingData = bookingDoc.data() as Map<String, dynamic>;
          String bookingDoctorName = (bookingData['doctorName']?.toString() ?? '')
              .toLowerCase()
              .replaceAll('dr.', '')
              .replaceAll('dr', '')
              .trim();
          String widgetDoctorName = widget.name
              .toLowerCase()
              .replaceAll('dr.', '')
              .replaceAll('dr', '')
              .trim();
          bool isVideoCall = bookingData['isVideoCall'] ?? false;

          String bookingDoctorFirstName = bookingDoctorName.split(' ').first;
          bool isDoctorMatch = bookingDoctorFirstName == widgetDoctorName || bookingDoctorName.contains(widgetDoctorName);
          bool shouldAddBooking = isDoctorMatch || isVideoCall;

          if (shouldAddBooking) {
            bookingData['bookingId'] = bookingDoc.id;
            bookingData['userEmail'] = userEmail;
            allBookings.add(bookingData);
          }
        }
      }

      yield allBookings;
    } catch (e) {
      print('Error fetching bookings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching bookings: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      yield [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
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
      ),
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(
              'Doctor Dashboard - ${widget.name.isEmpty ? "Unknown Doctor" : widget.name}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.menu, size: MediaQuery.of(context).size.width * 0.08),
                onPressed: () {
                  print('Drawer menu icon tapped');
                  _scaffoldKey.currentState?.openEndDrawer();
                },
                tooltip: 'Open Menu',
              ),
            ],
          ),
          endDrawer: FutureBuilder<String?>(
            future: _fetchDoctorImage(),
            builder: (context, snapshot) {
              bool isLoading = !snapshot.hasData && _isImageLoading;
              String? imageBase64 = snapshot.data;

              return Drawer(
                width: MediaQuery.of(context).size.width * 0.75,
                child: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[800]!, Colors.blue[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                                  : imageBase64 != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.memory(
                                  base64Decode(imageBase64),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    'assets/images/default_doctor.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                                  : Image.asset(
                                'assets/images/default_doctor.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.name.isEmpty ? "Unknown Doctor" : widget.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _uploadDoctorImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Upload Profile Image'),
                            ),
                          ],
                        ),
                      ),
                      _buildDrawerItem(
                        icon: Icons.account_circle,
                        title: 'Profile',
                        onTap: () {
                          print('Profile tapped');
                          Navigator.pop(context);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.settings,
                        title: 'Settings',
                        onTap: () {
                          print('Settings tapped');
                          Navigator.pop(context);
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsPage()),
                            );
                            print('Navigating to SettingsPage');
                          } catch (e) {
                            print('Navigation error: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error navigating to Settings: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      _buildDrawerItem(
                        icon: Icons.logout,
                        title: 'Logout',
                        color: Colors.red,
                        onTap: () {
                          print('Logout tapped');
                          Navigator.pop(context);
                          _logout();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue[50]!, Colors.grey[200]!],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RefreshIndicator(
                onRefresh: _refreshPage,
                color: Colors.blue[800],
                backgroundColor: Colors.white,
                displacement: 40.0,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _fetchDoctorBookings(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: 3,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: MediaQuery.of(context).size.width * 0.2,
                              color: Colors.red[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error Loading Bookings',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'An error occurred: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available,
                              size: MediaQuery.of(context).size.width * 0.2,
                              color: Colors.blue[200],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Appointments Found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No appointments match your criteria.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        var bookingData = snapshot.data![index];
                        String bookingId = bookingData['bookingId'];
                        String userEmail = bookingData['userEmail'];
                        String doctorName = bookingData['doctorName'] ?? 'Unknown Doctor';
                        String sessionName = bookingData['sessionName'] ?? 'Consultation Session';
                        String date = bookingData['date'] ?? 'Not specified';
                        String time = bookingData['time'] ?? 'Not specified';
                        num depositAmount = bookingData['depositAmount'] ?? 0;
                        bool isApproved = bookingData['doctorApproval'] ?? false;
                        String status = bookingData['status'] ?? 'pending';
                        String? prescriptionImage = bookingData['prescriptionImage'];

                        bool isFinished = status == 'finished';

                        return Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.email, color: Colors.blue[800]),
                                  title: Text(
                                    'Patient Email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  subtitle: Text(
                                    userEmail,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.person, color: Colors.blue[800]),
                                  title: Text(
                                    'Doctor',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  subtitle: Text(
                                    doctorName,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.event, color: Colors.blue[800]),
                                  title: Text(
                                    'Session Name',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  subtitle: Text(
                                    sessionName,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.calendar_today, color: Colors.blue[800]),
                                  title: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  subtitle: Text(
                                    date,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.access_time, color: Colors.blue[800]),
                                  title: Text(
                                    'Time',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  subtitle: Text(
                                    time,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.attach_money, color: Colors.blue[800]),
                                  title: Text(
                                    'Deposit Amount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$depositAmount EGP',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.info, color: Colors.blue[800]),
                                  title: Text(
                                    'Status',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  subtitle: Text(
                                    isFinished ? 'Finished' : isApproved ? 'Approved' : 'Pending',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isFinished
                                          ? Colors.grey[700]
                                          : isApproved
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (!isApproved && !isFinished)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isApproving
                                          ? null
                                          : () async => await _approveBooking(bookingId, userEmail),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[600],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: _isApproving
                                          ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : Text(
                                        'Approve Booking',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (isApproved && !isFinished) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isStartingCall
                                          ? null
                                          : () async => await _startVideoCall(bookingId, userEmail),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[800],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: _isStartingCall
                                          ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : Text(
                                        'Start Video Call',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isUploadingPrescription[bookingId] == true
                                          ? null
                                          : () async => await _uploadPrescriptionImage(bookingId, userEmail),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple[600],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: _isUploadingPrescription[bookingId] == true
                                          ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : Text(
                                        'Upload Prescription',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (prescriptionImage != null) ...[
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isDeletingPrescription[bookingId] == true
                                            ? null
                                            : () async => await _deletePrescriptionImage(bookingId, userEmail),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[600],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        child: _isDeletingPrescription[bookingId] == true
                                            ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                            : Text(
                                          'Delete Prescription',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isFinishingBooking[bookingId] == true
                                          ? null
                                          : () async => await _finishBooking(bookingId, userEmail),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: _isFinishingBooking[bookingId] == true
                                          ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : Text(
                                        'Finish Booking',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
                    ).animate().fadeIn(duration: 400.ms).slideY(
                      begin: -0.3,
                      end: 0,
                      duration: 400.ms,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color == Colors.red ? Colors.red : Colors.blue[800],
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color == Colors.red ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      hoverColor: Colors.blue[50],
    );
  }
}