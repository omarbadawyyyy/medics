import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AskADoctorPage extends StatefulWidget {
  @override
  _AskADoctorPageState createState() => _AskADoctorPageState();
}

class _AskADoctorPageState extends State<AskADoctorPage> {
  String? _selectedSpeciality;
  String? _selectedFor;
  String? _selectedGender;
  int _age = 0;

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _submitQuestion() async {
    // التأكد من تسجيل الدخول
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to submit a question')),
      );
      return;
    }

    if (_questionController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedSpeciality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _firestore.collection('questions').add({
        'email': user.email, // استخدام الإيميل من Firebase Authentication
        'speciality': _selectedSpeciality,
        'question': _questionController.text,
        'description': _descriptionController.text,
        'forWhom': _selectedFor ?? 'Not specified',
        'gender': _selectedGender ?? 'Not specified',
        'age': _age,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Question submitted successfully. Check My Activity for the response.')),
      );

      _questionController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedSpeciality = null;
        _selectedFor = null;
        _selectedGender = null;
        _age = 0;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting question: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ask a Doctor', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            Row(
              children: [
                Text('Choose a speciality', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('*', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSpeciality,
              items: [
                'Dermatology',
                'Dentistry',
                'Psychiatry',
                'Pediatrics',
                'Neurology',
                'Orthopedics',
                'Gynaecology',
                'ENT',
                'Cardiology',
                'Internal Medicine',
                'I don\'t know specialty',
              ].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSpeciality = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: Colors.blue[900]),
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
            SizedBox(height: 20),

            Row(
              children: [
                Text('Your question', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('*', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            SizedBox(height: 8),
            TextField(
              controller: _questionController,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: 'Enter your question',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),

            Text('Question description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('* (explanation of your medical symptoms)', style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLength: 250,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter your question description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),

            Text('The question is for', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFor = 'For myself'),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedFor == 'For myself' ? Colors.blue[900] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('For myself',
                            style: TextStyle(
                              color: _selectedFor == 'For myself' ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFor = 'For another person'),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedFor == 'For another person' ? Colors.blue[900] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('For another person',
                            style: TextStyle(
                              color: _selectedFor == 'For another person' ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            Text('Select your gender', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Male'),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'Male' ? Colors.blue[900] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('Male',
                            style: TextStyle(
                              color: _selectedGender == 'Male' ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'Female'),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'Female' ? Colors.blue[900] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('Female',
                            style: TextStyle(
                              color: _selectedGender == 'Female' ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            Text('How old are you?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('(years)', style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _age = int.tryParse(value) ?? 0;
                });
              },
              decoration: InputDecoration(
                hintText: 'Enter your age',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),

            Text(
              'Text answers on Medics are not intended for individual diagnosis, treatment or prescription. For these, please consult a doctor.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitQuestion,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Submit', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}