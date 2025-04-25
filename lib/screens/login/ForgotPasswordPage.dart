import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // إضافة مكتبة Firebase

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailError = false;
  bool _isLoading = false;

  // دالة لإرسال رسالة إعادة تعيين كلمة المرور عبر Firebase
  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      // استخدام Firebase لإرسال رابط إعادة تعيين كلمة المرور
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A password reset link has been sent to your email.')),
      );
    } catch (e) {
      print('Error sending email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email. Please try again later.')),
      );
    }
  }

  void _resetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _isEmailError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // تحقق من وجود البريد الإلكتروني في Firebase
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      // إرسال رابط إعادة تعيين كلمة المرور عبر Firebase
      await _sendPasswordResetEmail(email);
    } catch (e) {
      setState(() => _isEmailError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This email is not registered. Please sign up first.')),
      );
    }

    setState(() => _isLoading = false);
  }

  Widget _buildTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your email',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Enter your registered email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            prefixIcon: Icon(Icons.email, color: Colors.blue[900]),
            errorText: _isEmailError ? 'Email not found. Please check again' : null,
          ),
          onChanged: (value) {
            setState(() => _isEmailError = false);
          },
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _resetPassword,
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text('Reset Password', style: TextStyle(fontSize: 16, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[900],
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Forgot Password'),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          children: [
            Text(
              'Forgot your password?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),
            Text(
              'Enter your email below to receive a password reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 40),
            _buildTextField(),
            _buildResetButton(),
          ],
        ),
      ),
    );
  }
}
