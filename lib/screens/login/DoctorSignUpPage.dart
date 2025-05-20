import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart'; // استيراد صفحة تسجيل الدخول

// Assuming DoctorsData is accessible; import or define specialties
class DoctorsData {
  static final List<String> specialties = [
    'Cardiology',
    'Dentistry',
    'Dermatology',
    'Ear (ENT)',
    'Gynecology',
    'Internal Medicine',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
  ];
}

// List of Egyptian governorates
const List<String> egyptianGovernorates = [
  'Cairo',
  'Alexandria',
  'Giza',
  'Luxor',
  'Aswan',
  'Asyut',
  'Beheira',
  'Beni Suef',
  'Dakahlia',
  'Damietta',
  'Faiyum',
  'Gharbia',
  'Ismailia',
  'Kafr El Sheikh',
  'Matruh',
  'Minya',
  'Monufia',
  'New Valley',
  'North Sinai',
  'Port Said',
  'Qalyubia',
  'Qena',
  'Red Sea',
  'Sharqia',
  'Sohag',
  'South Sinai',
  'Suez',
];

class DoctorSignUpPage extends StatefulWidget {
  @override
  _DoctorSignUpPageState createState() => _DoctorSignUpPageState();
}

class _DoctorSignUpPageState extends State<DoctorSignUpPage> {
  bool _isAgreed = false;
  bool _isLoading = false;
  String _selectedCountryCode = '+20';
  String? _selectedSpeciality; // For specialty dropdown
  String? _selectedGovernorate; // For location dropdown

  // Controllers for remaining fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _feesController = TextEditingController();

  // Validation flags
  bool _isEmailValid = true;
  bool _isNameValid = true;
  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;
  bool _isPhoneValid = true;
  bool _isSpecialityValid = true;
  bool _isGovernorateValid = true;
  bool _isFeesValid = true;

  // Generate bio based on specialty
  String _generateBio(String specialty) {
    return 'Specialized in $specialty';
  }

  // Register doctor with Firebase Authentication and Firestore
  void _registerDoctor() async {
    if (_isLoading) return;

    bool isValid = true;

    // Validate fields
    if (_emailController.text.isEmpty ||
        !_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      setState(() => _isEmailValid = false);
      isValid = false;
    } else {
      setState(() => _isEmailValid = true);
    }

    if (_nameController.text.isEmpty) {
      setState(() => _isNameValid = false);
      isValid = false;
    } else {
      setState(() => _isNameValid = true);
    }

    if (_passwordController.text.isEmpty || _passwordController.text.length < 8) {
      setState(() => _isPasswordValid = false);
      isValid = false;
    } else {
      setState(() => _isPasswordValid = true);
    }

    if (_confirmPasswordController.text.isEmpty ||
        _confirmPasswordController.text != _passwordController.text) {
      setState(() => _isConfirmPasswordValid = false);
      isValid = false;
    } else {
      setState(() => _isConfirmPasswordValid = true);
    }

    if (_phoneController.text.isEmpty || double.tryParse(_phoneController.text.trim()) == null) {
      setState(() => _isPhoneValid = false);
      isValid = false;
    } else {
      setState(() => _isPhoneValid = true);
    }

    if (_selectedSpeciality == null) {
      setState(() => _isSpecialityValid = false);
      isValid = false;
    } else {
      setState(() => _isSpecialityValid = true);
    }

    if (_selectedGovernorate == null) {
      setState(() => _isGovernorateValid = false);
      isValid = false;
    } else {
      setState(() => _isGovernorateValid = true);
    }

    if (_feesController.text.isEmpty || double.tryParse(_feesController.text) == null) {
      setState(() => _isFeesValid = false);
      isValid = false;
    } else {
      setState(() => _isFeesValid = true);
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must agree to the terms and conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        // Add doctor data to Firestore in the 'doctors' collection
        await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'phone_code': _selectedCountryCode,
          'specialty': _selectedSpeciality,
          'trait': 'Skilled', // Default
          'location': _selectedGovernorate,
          'fees': double.parse(_feesController.text.trim()),
          'availability': 'Mon, 01 Jan 2026 02:00 PM', // Default
          'bio': _generateBio(_selectedSpeciality!),
          'rating': 0.0, // Default
          'numberOfReviews': 0, // Default
          'reviews': [], // Default
          'waitingTimeMinutes': 30, // Default
          'isSponsored': false, // Default
          'imageUrl': 'https://example.com/images/default_doctor.jpg', // Default
          'role': 'doctor', // To distinguish doctors from other users
        });

        // Note: Setting Custom Claims should ideally be done via Firebase Admin SDK on the server.
        // For demonstration, we'll show how to call a Cloud Function to set the claim.
        // You need to create a Firebase Cloud Function to handle this securely.

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! Please login to continue.')),
        );

        // Navigate to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register. Please try again later.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    required TextEditingController controller,
    required bool isValid,
    required String errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            errorText: isValid ? null : errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            DropdownButton<String>(
              value: _selectedCountryCode,
              items: [
                DropdownMenuItem(value: '+20', child: Text('Egypt (+20)')),
                DropdownMenuItem(value: '+966', child: Text('Saudi Arabia (+966)')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCountryCode = value!;
                });
              },
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter your phone number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  errorText: _isPhoneValid ? null : 'Invalid phone number',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSpecialityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your speciality',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSpeciality,
          hint: Text('Select speciality'),
          items: DoctorsData.specialties.map((specialty) {
            return DropdownMenuItem(
              value: specialty,
              child: Text(specialty),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSpeciality = value;
            });
          },
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.medical_services),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            errorText: _isSpecialityValid ? null : 'Please select a speciality',
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGovernorateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your governorate',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGovernorate,
          hint: Text('Select governorate'),
          items: egyptianGovernorates.map((governorate) {
            return DropdownMenuItem(
              value: governorate,
              child: Text(governorate),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGovernorate = value;
            });
          },
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            errorText: _isGovernorateValid ? null : 'Please select a governorate',
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(height: 40),
            Text(
              'Sign Up as a Doctor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            _buildTextField(
              label: 'Enter your email',
              hint: 'Enter email',
              icon: Icons.email,
              controller: _emailController,
              isValid: _isEmailValid,
              errorText: 'Invalid email',
            ),
            _buildTextField(
              label: 'Enter your name',
              hint: 'Enter name',
              icon: Icons.person,
              controller: _nameController,
              isValid: _isNameValid,
              errorText: 'Enter a valid name',
            ),
            _buildTextField(
              label: 'Enter your password',
              hint: 'Enter password',
              icon: Icons.lock,
              isPassword: true,
              controller: _passwordController,
              isValid: _isPasswordValid,
              errorText: 'Minimum 8 characters',
            ),
            _buildTextField(
              label: 'Confirm your password',
              hint: 'Confirm password',
              icon: Icons.lock,
              isPassword: true,
              controller: _confirmPasswordController,
              isValid: _isConfirmPasswordValid,
              errorText: 'Passwords do not match',
            ),
            _buildSpecialityDropdown(),
            _buildPhoneNumberField(),
            _buildGovernorateDropdown(),
            _buildTextField(
              label: 'Enter your fees (EGP)',
              hint: 'Enter fees',
              icon: Icons.money,
              keyboardType: TextInputType.number,
              controller: _feesController,
              isValid: _isFeesValid,
              errorText: 'Enter valid fees',
            ),
            Row(
              children: [
                Checkbox(
                  value: _isAgreed,
                  onChanged: (value) => setState(() => _isAgreed = value!),
                ),
                Text('I agree to the terms and conditions', style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _registerDoctor,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Create Account', style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _feesController.dispose();
    super.dispose();
  }
}