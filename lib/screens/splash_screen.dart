import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:medics/screens/login/login_page.dart'; // صفحة تسجيل الدخول
import 'package:shared_preferences/shared_preferences.dart'; // لتحميل البيانات المحفوظة
import 'Home_Page/Home_page.dart';
import 'welcome_page.dart'; // استيراد الصفحة الترحيبية الجديدة

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // تهيئة Firebase
  print('Firebase Project ID: ${Firebase.app().options.projectId}'); // طباعة معرف المشروع
  print('Current User after initialization: ${FirebaseAuth.instance.currentUser}'); // طباعة المستخدم الحالي
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[900],
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: SplashScreen(), // عرض شاشة البداية أولًا
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    Future.delayed(Duration(seconds: 3), () async {
      User? user = FirebaseAuth.instance.currentUser;
      print('Current User in SplashScreen: $user');

      if (user != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? email = user.email;
        String? name = prefs.getString('name_${email}') ?? '';
        String? phone = prefs.getString('phone_${email}') ?? '';
        String? imagePath = prefs.getString('profileImagePath_${email}');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              email: email ?? '',
              name: name,
              phone: phone,
              imagePath: imagePath,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomePage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/logo.png',
                height: 120,
                width: 120,
              ),
            ),
            SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                '',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}