import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart'; // استيراد صفحة تسجيل الدخول

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _isAgreed = false;
  bool _isLoading = false;
  String _selectedCountryCode = '+20';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isEmailValid = true;
  bool _isNameValid = true;
  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;
  bool _isPhoneValid = true;

  // تسجيل المستخدم باستخدام Firebase Authentication
  void _registerUser() async {
    if (_isLoading) return;

    bool isValid = true;

    // التحقق من صحة الحقول
    if (_emailController.text.isEmpty || !_emailController.text.contains('@') || !_emailController.text.contains('.')) {
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

    if (_confirmPasswordController.text.isEmpty || _confirmPasswordController.text != _passwordController.text) {
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
      // محاولة إنشاء حساب باستخدام Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // إضافة بيانات المستخدم إلى Firestore بعد نجاح التسجيل
      await FirebaseFirestore.instance.collection('users').add({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'phone': _phoneController.text,
        'phone_code': _selectedCountryCode,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful!')),
      );

      // الانتقال إلى صفحة تسجيل الدخول بعد النجاح
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      // إذا حدث خطأ أثناء التسجيل
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register. Please try again later.')),
      );
    }

    setState(() => _isLoading = false);
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
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
              'Sign Up',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            _buildTextField(label: 'Enter your email', hint: 'Enter email', icon: Icons.email, controller: _emailController, isValid: _isEmailValid, errorText: 'Invalid email'),
            _buildTextField(label: 'Enter your name', hint: 'Enter name', icon: Icons.person, controller: _nameController, isValid: _isNameValid, errorText: 'Enter a valid name'),
            _buildTextField(label: 'Enter your password', hint: 'Enter password', icon: Icons.lock, isPassword: true, controller: _passwordController, isValid: _isPasswordValid, errorText: 'Minimum 8 characters'),
            _buildTextField(label: 'Confirm your password', hint: 'Confirm password', icon: Icons.lock, isPassword: true, controller: _confirmPasswordController, isValid: _isConfirmPasswordValid, errorText: 'Passwords do not match'),
            _buildPhoneNumberField(),
            Row(
              children: [
                Checkbox(value: _isAgreed, onChanged: (value) => setState(() => _isAgreed = value!)),
                Text('I agree to the terms and conditions', style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _registerUser,
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Create Account', style: TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], minimumSize: Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
