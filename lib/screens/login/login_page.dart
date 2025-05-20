import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medics/screens/login/signupPage.dart';
import '../Home_Page/Home_page.dart';
import '../DoctorDashboard/doctor_dashboard.dart';
import 'forgotPasswordPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isEmailError = false;
  bool _isPasswordError = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isEmailError = email.isEmpty;
        _isPasswordError = password.isEmpty;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // تسجيل الدخول باستخدام Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // الحصول على المستخدم المسجل الدخول
      User? user = userCredential.user;
      if (user != null) {
        String userEmail = user.email ?? '';
        String userPhone = user.phoneNumber ?? '';
        String? userPhotoUrl = user.photoURL;

        // التحقق مما إذا كان المستخدم طبيبًا أو مستخدمًا عاديًا بالاستعلام عن Firestore
        final firestore = FirebaseFirestore.instance;

        // استعلام مجموعة 'doctors'
        QuerySnapshot doctorSnapshot = await firestore
            .collection('doctors')
            .where('email', isEqualTo: userEmail)
            .get();

        // استعلام مجموعة 'users'
        QuerySnapshot userSnapshot = await firestore
            .collection('users')
            .where('email', isEqualTo: userEmail)
            .get();

        // جلب الاسم من Firestore إذا كان الدكتور موجود
        String userName = '';
        if (doctorSnapshot.docs.isNotEmpty) {
          userName = doctorSnapshot.docs.first['name'] ?? 'Unknown Doctor';
        } else if (userSnapshot.docs.isNotEmpty) {
          userName = userSnapshot.docs.first['name'] ?? 'Unknown User';
        }

        // عرض رسالة النجاح
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Successful")));

        // التوجيه بناءً على نوع المستخدم
        Future.delayed(Duration(seconds: 1), () {
          if (doctorSnapshot.docs.isNotEmpty) {
            // إذا كان البريد موجودًا في مجموعة الأطباء، توجّه إلى DoctorDashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorDashboard(
                  email: userEmail,
                  name: userName,
                  phone: userPhone,
                  imagePath: userPhotoUrl,
                  doctorEmail: userEmail,
                ),
              ),
            );
          } else if (userSnapshot.docs.isNotEmpty) {
            // إذا كان البريد موجودًا في مجموعة المستخدمين، توجّه إلى HomePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  email: userEmail,
                  name: userName,
                  phone: userPhone,
                  imagePath: userPhotoUrl,
                ),
              ),
            );
          } else {
            // إذا لم يكن البريد موجودًا في أي مجموعة، اعرض رسالة خطأ
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("User not found in doctors or users collection.")),
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _isPasswordError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Incorrect password. Please try again.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.blue[900],
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Center(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(seconds: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 40),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter your email',
                      errorText: _isEmailError ? 'Please enter a valid email' : null,
                      prefixIcon: Icon(Icons.email, color: Colors.blue[900]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: _isEmailError ? Colors.red : Colors.blue[900]!,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _isEmailError = false);
                    },
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      errorText: _isPasswordError ? 'Incorrect password' : null,
                      prefixIcon: Icon(Icons.lock, color: Colors.blue[900]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.blue[900],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: _isPasswordError ? Colors.red : Colors.blue[900]!,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _isPasswordError = false);
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => ForgotPasswordPage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);
                                return SlideTransition(position: offsetAnimation, child: child);
                              },
                              transitionDuration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  AnimatedContainer(
                    duration: Duration(seconds: 1),
                    curve: Curves.easeInOut,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide(color: Colors.blue[900]!, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => SignUpPage(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                          transitionDuration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: AnimatedDefaultTextStyle(
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      duration: Duration(milliseconds: 500),
                      child: Text(
                        'Don\'t have an account? Sign Up',
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text('Or sign in with', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.g_mobiledata, size: 40, color: Colors.red),
                        onPressed: () {},
                      ),
                      SizedBox(width: 20),
                      IconButton(
                        icon: Icon(Icons.apple, size: 40, color: Colors.black),
                        onPressed: () {},
                      ),
                      SizedBox(width: 20),
                      IconButton(
                        icon: Icon(Icons.facebook, size: 40, color: Colors.blue),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
