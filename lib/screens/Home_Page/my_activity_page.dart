import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class MyActivityPage extends StatefulWidget {
  @override
  _MyActivityPageState createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _geminiApiKey = "AIzaSyBktPI-UXkVe48F647saaMHuby7WoNjz1I";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _detectLanguage(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(text)) {
      return 'Arabic';
    }
    return 'English';
  }

  Future<String> _getAIResponse(String userMessage, String language) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_geminiApiKey');

    final prompt = language == 'Arabic'
        ? """
أنت مساعد طبي ذكي مصمم لتقديم معلومات طبية عامة. المستخدم طرح السؤال التالي: "$userMessage". قدم إجابة مفيدة ودقيقة باللغة العربية، وأضف تنبيهًا بأن هذه المعلومات ليست بديلاً عن استشارة طبيب مختص، ويجب على المستخدم استشارة طبيب للتشخيص أو العلاج.
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
        String aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        return aiResponse;
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting AI response: $e');
      return language == 'Arabic'
          ? 'عذرًا، لم أتمكن من معالجة طلبك. حاول مرة أخرى لاحقًا.\n\n**تنبيه**: هذه المعلومات ليست بديلاً عن استشارة طبيب مختص. يرجى استشارة طبيب للتشخيص أو العلاج.'
          : 'Sorry, I couldn’t process your request. Please try again later.\n\n**Disclaimer**: This is not a substitute for professional medical advice. Please consult a doctor for diagnosis or treatment.';
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

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Booking canceled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error canceling booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.question_answer, size: 20),
                    text: 'Questions',
                  ),
                  Tab(
                    icon: Icon(Icons.event, size: 20),
                    text: 'Doctor Visits',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
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
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No questions found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
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
                              question: question,
                              description: description,
                              speciality: speciality,
                              status: status,
                              aiResponse: 'Generating response...',
                              isLoading: true,
                            );
                          }

                          return _buildQuestionCard(
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
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('bookings')
                        .doc(FirebaseAuth.instance.currentUser?.email)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(
                          child: Text(
                            'No bookings found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      var bookingData = snapshot.data!.data() as Map<String, dynamic>;
                      String bookingId = snapshot.data!.id;
                      String doctorName = bookingData['doctorName'] ?? 'Unknown Doctor';
                      String date = bookingData['date'] ?? 'Not specified';
                      String time = bookingData['time'] ?? 'Not specified';
                      double depositAmount = (bookingData['depositAmount'] ?? 0.0).toDouble();
                      String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email';

                      return ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          _buildBookingCard(
                            bookingId: bookingId,
                            doctorName: doctorName,
                            date: date,
                            time: time,
                            depositAmount: depositAmount,
                            userName: userEmail,
                          ),
                        ],
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
    required String question,
    required String description,
    required String speciality,
    required String status,
    required String aiResponse,
    required bool isLoading,
  }) {
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.question_answer, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Question: $question',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.description, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Description: $description',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Speciality: $speciality',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Status: $status',
                    style: TextStyle(
                      fontSize: 16,
                      color: status == 'answered' ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Doctor\'s Response: $aiResponse',
                      style: TextStyle(
                        fontSize: 16,
                        color: isLoading ? Colors.blue : Colors.blue[900],
                        fontStyle: isLoading ? FontStyle.italic : FontStyle.normal,
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

  Widget _buildBookingCard({
    required String bookingId,
    required String doctorName,
    required String date,
    required String time,
    required double depositAmount,
    required String userName,
  }) {
    return Card(
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue[200],
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doctor: $doctorName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Booked by: $userName',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey, thickness: 0.5),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Date: $date',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.access_time, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Time: $time',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payment, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Deposit Paid: ${depositAmount.toStringAsFixed(0)} EGP',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
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
                      await _cancelBooking(bookingId);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.cancel, size: 20),
                  label: const Text('Cancel Booking', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}