import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Home_Page/Home_page.dart';
import '../login/login_page.dart';

class MyProfilePage extends StatefulWidget {
  final String email; // استلام البريد الإلكتروني من الصفحة السابقة

  MyProfilePage({required this.email});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<MyProfilePage> {
  String name = ''; // اسم المستخدم
  String phoneNumber = ''; // رقم الهاتف
  File? _profileImage; // متغير لتخزين الصورة المختارة
  String? _imagePath; // مسار الصورة المحفوظة

  @override
  void initState() {
    super.initState();
    _loadUserData(); // تحميل البيانات من SharedPreferences
    _getUserData(); // جلب البيانات من Firebase
    _loadProfileImage(); // تحميل الصورة المحفوظة
  }

  // تحميل البيانات من SharedPreferences
  _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name_${widget.email}') ?? ''; // استخدام البريد كمفتاح
      phoneNumber = prefs.getString('phone_${widget.email}') ?? ''; // استخدام البريد كمفتاح
    });
  }

  // جلب البيانات من Firebase Firestore باستخدام البريد الإلكتروني
  _getUserData() async {
    if (name.isEmpty && phoneNumber.isEmpty) {
      print("Fetching data for email: ${widget.email}");
      try {
        // استعلام لجلب بيانات المستخدم من Firestore باستخدام البريد الإلكتروني
        var userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: widget.email)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var user = userSnapshot.docs.first.data();
          setState(() {
            name = user['name'];
            phoneNumber = user['phone'];
          });

          // حفظ البيانات في SharedPreferences باستخدام البريد كمفتاح
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('name_${widget.email}', name);
          prefs.setString('phone_${widget.email}', phoneNumber);
        } else {
          print("User not found");
        }
      } catch (e) {
        print("Error fetching data: $e");
      }
    }
  }

  // تحميل الصورة المحفوظة من SharedPreferences بناءً على البريد الإلكتروني
  _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedImagePath = prefs.getString('profileImagePath_${widget.email}');
    if (savedImagePath != null && savedImagePath.isNotEmpty) {
      setState(() {
        _imagePath = savedImagePath;
        _profileImage = File(savedImagePath);
      });
    }
  }

  // اختيار الصورة باستخدام image_picker
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // حفظ الصورة في التخزين المحلي
      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/profile_image_${widget.email.hashCode}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File newImage = await File(image.path).copy(path);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath_${widget.email}', path); // حفظ المسار باستخدام البريد كمفتاح

      setState(() {
        _profileImage = newImage;
        _imagePath = path;
      });
    }
  }

  // التعامل مع زر الرجوع من الهاتف
  Future<bool> _onWillPop() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(email: widget.email, name: '', phone: '',)),
    );
    return false;
  }

  // دالة تسجيل الخروج
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut(); // تسجيل الخروج من Firebase
      Navigator.pushReplacement(
        context,
        _createSlideRoute(LoginPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  // دالة لإنشاء أنيميشن الانتقال
  PageRouteBuilder _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
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
      transitionDuration: Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // عرض الصورة الشخصية مع الاسم ورقم الهاتف
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                          child: _profileImage == null
                              ? Icon(Icons.person, size: 40, color: Colors.blue[900])
                              : null,
                        ),
                        Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue[900],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Loading...' : name,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),
                      Text(
                        phoneNumber.isEmpty ? 'Loading...' : phoneNumber,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 40),

              // قائمة الخيارات مع الأنيميشن والفواصل
              Column(
                children: [
                  _buildListTile('Shamel', Icons.account_circle),
                  Divider(color: Colors.grey[300], thickness: 1, indent: 16, endIndent: 16),
                  _buildListTile('My Account', Icons.account_box),
                  Divider(color: Colors.grey[300], thickness: 1, indent: 16, endIndent: 16),
                  _buildListTile('Insurance', Icons.shield),
                  Divider(color: Colors.grey[300], thickness: 1, indent: 16, endIndent: 16),
                  _buildListTile('Manage Cards', Icons.credit_card),
                  Divider(color: Colors.grey[300], thickness: 1, indent: 16, endIndent: 16),
                  _buildListTile('My Questions', Icons.question_answer),
                  Divider(color: Colors.grey[300], thickness: 1, indent: 16, endIndent: 16),
                  _buildListTile('Favorites', Icons.favorite),
                  Divider(color: Colors.grey[300], thickness: 1, indent: 16, endIndent: 16),
                  _buildListTile('Medics Points', Icons.star),
                  Divider(color: Colors.grey[300], thickness: 1, indent: 16, endIndent: 16),
                  _buildListTile('Support', Icons.headset_mic),
                  Divider(color: Colors.grey[300], thickness: 1, indent: 16, endIndent: 16),
                  _buildListTile('Settings', Icons.settings),
                  Divider(color: Colors.grey[300], thickness: 1, indent: 16, endIndent: 16),
                  _buildListTile('Rate the app', Icons.star_border),
                  Divider(color: Colors.grey[300], thickness: 1, indent: 16, endIndent: 16),
                  _buildListTile('Log Out', Icons.logout, onTap: _logout),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لبناء العناصر في القائمة مع الأنيميشن
  Widget _buildListTile(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[900], size: 28),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[500]),
      onTap: onTap ?? () {
        print('$title tapped');
      },
    ).animate().fadeIn(duration: 500.ms).scale();
  }
}
