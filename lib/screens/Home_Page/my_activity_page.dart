import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:medics/screens/Home_Page/doctor_call/video_call_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MyActivityPage extends StatefulWidget {
  @override
  _MyActivityPageState createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _geminiApiKey = "AIzaSyBktPI-UXkVe48F647saaMHuby7WoNjz1I";
  late TabController _tabController;

  // Agora variables
  static const String agoraAppId = '286f325dbb1349ea99178d2e8fed6217';
  late RtcEngine _engine;
  bool _isEngineInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initAgora();
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_isEngineInitialized) {
      print('Disposing Agora engine in MyActivityPage');
      _engine.leaveChannel();
      _engine.release();
    }
    super.dispose();
  }

  Future<void> _initAgora() async {
    try {
      print('Initializing Agora engine with App ID: $agoraAppId');
      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: agoraAppId,
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

      print('Agora engine initialized successfully');
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

  Future<void> _joinVideoCall(String channelName, {String? bookingId}) async {
    if (!_isEngineInitialized) {
      print('Agora engine not initialized');
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

      print('Enabling video and starting preview...');
      await _engine.enableVideo();
      await _engine.startPreview();

      String sanitizedChannelName = channelName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
      if (sanitizedChannelName.isEmpty || sanitizedChannelName.length > 64) {
        throw Exception('Invalid channel name: $sanitizedChannelName');
      }
      print('Joining channel: $sanitizedChannelName');

      if (bookingId != null) {
        await _firestore
            .collection('bookings')
            .doc(FirebaseAuth.instance.currentUser?.email)
            .collection('userBookings')
            .doc(bookingId)
            .update({'callStatus': 'accepted'});
      }

      if (mounted) {
        print('Navigating to VideoCallScreen');
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
      print('Error joining video call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining video call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPrescription(String base64Image, String bookingId) async {
    try {
      // Request appropriate storage permission
      bool hasPermission = false;
      if (Platform.isAndroid) {
        // For Android, request Permission.photos (preferred for Android 13+)
        var status = await Permission.photos.request();
        if (status.isGranted) {
          hasPermission = true;
        } else if (status.isDenied) {
          print('Photos permission denied');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Photos permission is required to download the prescription.'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => _downloadPrescription(base64Image, bookingId),
                ),
              ),
            );
          }
          return;
        } else if (status.isPermanentlyDenied) {
          print('Photos permission permanently denied');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Photos permission is permanently denied. Please enable it in settings.'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () async {
                    await openAppSettings();
                  },
                ),
              ),
            );
          }
          return;
        }
      } else if (Platform.isIOS) {
        // For iOS, request photo library access
        var status = await Permission.photos.request();
        if (status.isGranted) {
          hasPermission = true;
        } else {
          print('Photos permission denied on iOS');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Photo library access is required to download the prescription.'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () async {
                    await openAppSettings();
                  },
                ),
              ),
            );
          }
          return;
        }
      }

      if (!hasPermission) {
        print('No storage permission granted');
        return;
      }

      // Decode Base64 image
      final bytes = base64Decode(base64Image);

      // Save to Downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not access Downloads directory');
      }
      final filePath = '${directory.path}/prescription_$bookingId.jpg';
      final file = File(filePath);

      // Write the image to file
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prescription downloaded to $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error downloading prescription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading prescription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAndStoreResponse(String questionId, String userMessage) async {
    String language = _detectLanguage(userMessage);
    String aiResponse = await _getAIResponse(userMessage, language);

    await _firestore.collection('questions').doc(questionId).update({
      'aiResponse': aiResponse,
      'status': 'answered',
      'responseTimestamp': FieldValue.serverTimestamp(),
    });
  }

  String _detectLanguage(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text) ? 'Arabic' : 'English';
  }

  Future<String> _getAIResponse(String userMessage, String language) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_geminiApiKey');

    final prompt = language == 'Arabic'
        ? """
You are a smart medical assistant designed to provide general medical information. The user asked the following question: "$userMessage". Provide a helpful and accurate response in Arabic, and include a disclaimer that this information is not a substitute for professional medical advice, and the user should consult a doctor for diagnosis or treatment.
"""
        : """
You are a medical assistant AI designed to provide general medical information. The user has asked the following question: "$userMessage". Provide a helpful and accurate response in English, and include a disclaimer that this is not a substitute for professional medical advice, and the user should consult a doctor for diagnosis or treatment.
""";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting AI response: $e');
      return language == 'Arabic'
          ? 'عذرًا، لم أتمكن من معالجة طلبك. حاول مرة أخرى لاحقًا.\n\n**تنبيه**: هذه المعلومات ليست بديلاً عن النصيحة الطبية المهنية. يرجى استشارة طبيب للتشخيص أو العلاج.'
          : 'Sorry, I couldn’t process your request. Please try again later.\n\n**Disclaimer**: This is not a substitute for professional medical advice. Please consult a doctor for diagnosis or treatment.';
    }
  }

  Future<void> _cancelBooking(String bookingId, String collectionPath) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(FirebaseAuth.instance.currentUser?.email)
          .collection(collectionPath == 'bookings' ? 'userBookings' : 'bookings')
          .doc(bookingId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking canceled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error canceling booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error canceling booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Question canceled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error canceling question: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error canceling question: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.grey[100]!],
          ),
        ),
        child: Column(
          children: [
            Container(
              color: Colors.blue[900],
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                ),
                tabs: [
                  Tab(
                    icon: Icon(
                      Icons.question_answer,
                      size: MediaQuery.of(context).size.width * 0.05,
                    ),
                    text: 'Questions',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.event,
                      size: MediaQuery.of(context).size.width * 0.05,
                    ),
                    text: 'Doctor Visits',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.home,
                      size: MediaQuery.of(context).size.width * 0.05,
                    ),
                    text: 'Home Care',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Questions
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('questions')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.04,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No questions found',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.045,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        cacheExtent: 9999,
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var questionDoc = snapshot.data!.docs[index];
                          var questionData = questionDoc.data() as Map<String, dynamic>;
                          String questionId = questionDoc.id;
                          String question = questionData['question'] ?? 'No question';
                          String description = questionData['description'] ?? 'No description';
                          String speciality = questionData['speciality'] ?? 'I don\'t know specialty';
                          String status = questionData['status'] ?? 'pending';
                          String? aiResponse = questionData['aiResponse'];

                          if (aiResponse == null && status == 'pending') {
                            String userMessage = "Question: $question\nDescription: $description";
                            _generateAndStoreResponse(questionId, userMessage);
                            return _buildQuestionCard(
                              questionId: questionId,
                              question: question,
                              description: description,
                              speciality: speciality,
                              status: status,
                              aiResponse: 'Generating response...',
                              isLoading: true,
                            );
                          }

                          return _buildQuestionCard(
                            questionId: questionId,
                            question: question,
                            description: description,
                            speciality: speciality,
                            status: status,
                            aiResponse: aiResponse ?? 'Waiting for response',
                            isLoading: false,
                          );
                        },
                      );
                    },
                  ),

                  // Tab 2: Doctor Visits
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('bookings')
                        .doc(FirebaseAuth.instance.currentUser?.email)
                        .collection('userBookings')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.04,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No bookings found',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.045,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        cacheExtent: 9999,
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var bookingDoc = snapshot.data!.docs[index];
                          var bookingData = bookingDoc.data() as Map<String, dynamic>;
                          String bookingId = bookingDoc.id;
                          String doctorName = bookingData['doctorName'] ?? 'Unknown Doctor';
                          String date = bookingData['date'] ?? 'Not specified';
                          String time = bookingData['time'] ?? 'Not specified';
                          double depositAmount = (bookingData['depositAmount'] ?? 0.0).toDouble();
                          String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email';
                          bool isVideoCall = bookingData['isVideoCall'] ?? false;
                          bool doctorApproval = bookingData['doctorApproval'] ?? false;
                          String? videoCallLink = bookingData['videoCallLink'];
                          String? prescriptionImage = bookingData['prescriptionImage'];

                          return _buildBookingCard(
                            bookingId: bookingId,
                            doctorName: doctorName,
                            date: date,
                            time: time,
                            depositAmount: depositAmount,
                            userName: userEmail,
                            isVideoCall: isVideoCall,
                            doctorApproval: doctorApproval,
                            videoCallLink: videoCallLink,
                            collectionPath: 'bookings',
                            prescriptionImage: prescriptionImage,
                          );
                        },
                      );
                    },
                  ),

                  // Tab 3: Home Care
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('booking_home_care')
                        .doc(FirebaseAuth.instance.currentUser?.email)
                        .collection('bookings')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.04,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No home care bookings found',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.045,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        cacheExtent: 9999,
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var bookingDoc = snapshot.data!.docs[index];
                          var bookingData = bookingDoc.data() as Map<String, dynamic>;
                          String bookingId = bookingDoc.id;
                          String service = bookingData['service'] ?? 'Unknown Service';
                          String date = bookingData['timestamp'] != null
                              ? (bookingData['timestamp'] as Timestamp).toDate().toString().split(' ')[0]
                              : 'Not specified';
                          String time = bookingData['timestamp'] != null
                              ? (bookingData['timestamp'] as Timestamp).toDate().toString().split(' ')[1].substring(0, 5)
                              : 'Not specified';
                          String area = bookingData['area'] ?? 'Not specified';
                          String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email';

                          return _buildHomeCareCard(
                            bookingId: bookingId,
                            service: service,
                            date: date,
                            time: time,
                            area: area,
                            userName: userEmail,
                            collectionPath: 'booking_home_care',
                          );
                        },
                      );
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

  Widget _buildQuestionCard({
    required String questionId,
    required String question,
    required String description,
    required String speciality,
    required String status,
    required String aiResponse,
    required bool isLoading,
  }) {
    final isArabic = _detectLanguage(question) == 'Arabic' || _detectLanguage(description) == 'Arabic';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;
    final iconAlignment = isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Directionality(
          textDirection: textDirection,
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            child: Column(
              crossAxisAlignment: iconAlignment,
              children: [
                Row(
                  mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        isArabic ? 'السؤال: $question' : 'Question: $question',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: textDirection,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    Icon(
                      Icons.question_answer,
                      color: Colors.blue,
                      size: MediaQuery.of(context).size.width * 0.05,
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Row(
                  mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        isArabic ? 'الوصف: $description' : 'Description: $description',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.black54,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textDirection: textDirection,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    Icon(
                      Icons.description,
                      color: Colors.grey,
                      size: MediaQuery.of(context).size.width * 0.05,
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Row(
                  mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        isArabic ? 'التخصص: $speciality' : 'Speciality: $speciality',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: textDirection,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    Icon(
                      Icons.medical_services,
                      color: Colors.grey,
                      size: MediaQuery.of(context).size.width * 0.05,
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Row(
                  mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'الحالة: $status' : 'Status: $status',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        color: status == 'answered' ? Colors.green : Colors.orange,
                      ),
                      textDirection: textDirection,
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    Icon(
                      Icons.info,
                      color: Colors.grey,
                      size: MediaQuery.of(context).size.width * 0.05,
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Row(
                  mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        isArabic ? 'رد الطبيب: $aiResponse' : 'Doctor\'s Response: $aiResponse',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: isLoading ? Colors.blue : Colors.blue[900],
                          fontStyle: isLoading ? FontStyle.italic : FontStyle.normal,
                        ),
                        textDirection: textDirection,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: MediaQuery.of(context).size.width * 0.05,
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Align(
                  alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          title: Text(isArabic ? 'إلغاء السؤال' : 'Cancel Question'),
                          content: Text(isArabic
                              ? 'هل أنت متأكد أنك تريد إلغاء هذا السؤال؟'
                              : 'Are you sure you want to cancel this question?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                isArabic ? 'لا' : 'No',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                isArabic ? 'نعم' : 'Yes',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _cancelQuestion(questionId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                        vertical: MediaQuery.of(context).size.height * 0.015,
                      ),
                      elevation: 3,
                    ),
                    icon: Icon(
                      Icons.cancel,
                      size: MediaQuery.of(context).size.width * 0.05,
                    ),
                    label: Text(
                      isArabic ? 'إلغاء السؤال' : 'Cancel Question',
                      style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
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

  Widget _buildBookingCard({
    required String bookingId,
    required String doctorName,
    required String date,
    required String time,
    required double depositAmount,
    required String userName,
    required bool isVideoCall,
    required bool doctorApproval,
    String? videoCallLink,
    required String collectionPath,
    String? prescriptionImage,
  }) {
    return ClipRect(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: MediaQuery.of(context).size.width * 0.06,
                      backgroundColor: Colors.blue[200],
                      child: Icon(
                        Icons.person,
                        size: MediaQuery.of(context).size.width * 0.07,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.05,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                          Text(
                            'Booked by: $userName',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.04,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                const Divider(color: Colors.grey, thickness: 0.5),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    Expanded(
                      child: Text(
                        'Date: $date',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.access_time,
                        color: Colors.blue,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    Expanded(
                      child: Text(
                        'Time: $time',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isVideoCall ? Icons.videocam : Icons.person,
                        color: Colors.blue,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    Expanded(
                      child: Text(
                        'Type: ${isVideoCall ? 'Video Call' : 'In-Person Appointment'}',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: Colors.blue,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    Text(
                      'Deposit Paid: ${depositAmount.toStringAsFixed(0)} EGP',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                if (isVideoCall)
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          doctorApproval ? Icons.check_circle : Icons.hourglass_empty,
                          color: doctorApproval ? Colors.green : Colors.orange,
                          size: MediaQuery.of(context).size.width * 0.05,
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                      Text(
                        doctorApproval ? 'Approved by Doctor' : 'Waiting for Doctor Approval',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: doctorApproval ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.description,
                        color: Colors.blue,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    Expanded(
                      child: Text(
                        'Prescription:',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                prescriptionImage != null && prescriptionImage.isNotEmpty
                    ? Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: Container(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.memory(
                                    base64Decode(prescriptionImage),
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Text(
                                      'Error loading prescription image',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[700],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Image.memory(
                        base64Decode(prescriptionImage),
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: MediaQuery.of(context).size.height * 0.15,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Text(
                          'Error loading prescription image',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.42,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _downloadPrescription(prescriptionImage, bookingId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.03,
                            vertical: MediaQuery.of(context).size.height * 0.015,
                          ),
                          elevation: 3,
                        ),
                        icon: Icon(
                          Icons.download,
                          size: MediaQuery.of(context).size.width * 0.05,
                        ),
                        label: Text(
                          'Download Prescription',
                          style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                )
                    : Text(
                  'No prescription available',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.42,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              title: const Text('Cancel Booking'),
                              content: const Text('Are you sure you want to cancel this booking?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('No', style: TextStyle(color: Colors.blue)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Yes', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _cancelBooking(bookingId, collectionPath);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.03,
                            vertical: MediaQuery.of(context).size.height * 0.015,
                          ),
                          elevation: 3,
                        ),
                        icon: Icon(
                          Icons.cancel,
                          size: MediaQuery.of(context).size.width * 0.05,
                        ),
                        label: Text(
                          'Cancel Booking',
                          style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (isVideoCall)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.42,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: doctorApproval && videoCallLink != null && videoCallLink.isNotEmpty
                              ? () async {
                            await _joinVideoCall(videoCallLink, bookingId: bookingId);
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: doctorApproval ? Colors.green[700] : Colors.grey[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.03,
                              vertical: MediaQuery.of(context).size.height * 0.015,
                            ),
                            elevation: doctorApproval ? 3 : 0,
                          ),
                          icon: Icon(
                            Icons.videocam,
                            size: MediaQuery.of(context).size.width * 0.05,
                          ),
                          label: Text(
                            'Join Video Call',
                            style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeCareCard({
    required String bookingId,
    required String service,
    required String date,
    required String time,
    required String area,
    required String userName,
    required String collectionPath,
  }) {
    return ClipRect(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: MediaQuery.of(context).size.width * 0.06,
                      backgroundColor: Colors.blue[200],
                      child: Icon(
                        Icons.medical_services,
                        size: MediaQuery.of(context).size.width * 0.07,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.05,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                          Text(
                            'Booked by: $userName',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.04,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                const Divider(color: Colors.grey, thickness: 0.5),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    Expanded(
                      child: Text(
                        'Date: $date',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.access_time,
                        color: Colors.blue,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    Expanded(
                      child: Text(
                        'Time: $time',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    Expanded(
                      child: Text(
                        'Area: $area',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.42,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              title: const Text('Cancel Booking'),
                              content: const Text('Are you sure you want to cancel this booking?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('No', style: TextStyle(color: Colors.blue)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Yes', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _cancelBooking(bookingId, collectionPath);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.03,
                            vertical: MediaQuery.of(context).size.height * 0.015,
                          ),
                          elevation: 3,
                        ),
                        icon: Icon(
                          Icons.cancel,
                          size: MediaQuery.of(context).size.width * 0.05,
                        ),
                        label: Text(
                          'Cancel Booking',
                          style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
