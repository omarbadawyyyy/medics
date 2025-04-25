import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/Home_page.dart';
import 'package:medics/screens/Home_Page/pharmacy/medicine_database_helper.dart';
import 'package:medics/screens/welcome_page.dart'; // الصفحة الرئيسية
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:medics/screens/login/login_page.dart'; // صفحة تسجيل الدخول
import 'package:shared_preferences/shared_preferences.dart'; // لتحميل البيانات المحفوظة

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // تهيئة Firebase
  await MedicineDatabaseHelper().addMedicines(); // تعبئة قاعدة البيانات (السطر الجديد)

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

    // إعداد الانيميشن لظهور الشعار والنص تدريجيًا
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    // التحقق من حالة المستخدم في Firebase وتحميل البيانات
    Future.delayed(Duration(seconds: 3), () async {
      User? user = FirebaseAuth.instance.currentUser;
      print('Current User in SplashScreen: $user'); // طباعة المستخدم الحالي

      if (user != null) {
        // إذا كان المستخدم مسجل الدخول، تحميل البيانات من SharedPreferences
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
        // إذا لم يكن المستخدم مسجلاً الدخول، يتم توجيهه إلى صفحة تسجيل الدخول
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
      backgroundColor: Colors.white, // خلفية بيضاء نظيفة
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/logo.png', // تأكد من وجود الصورة في assets
                height: 120, // حجم مناسب
                width: 120,
              ),
            ),
            SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                '', // عرض النص بدون "App"
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
