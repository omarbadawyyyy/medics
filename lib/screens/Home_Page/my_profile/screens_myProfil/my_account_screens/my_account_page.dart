import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'change_password_page.dart';
import 'address_managment/address_management_page.dart';

class MyAccountPage extends StatefulWidget {
  final String email;

  MyAccountPage({required this.email});

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  String name = '';
  String phoneNumber = '';
  String email = '';
  DateTime? birthDate;
  String gender = '';
  int addressCount = 0; // متغير لتخزين عدد العناوين
  bool isLoading = true;
  bool isEditing = false;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    _fetchUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        isLoading = true;
      });

      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        var user = userSnapshot.docs.first.data();
        var docRef = userSnapshot.docs.first.reference;

        // التحقق من وجود حقل address وتحويله إلى addresses إذا لزم الأمر
        if (user.containsKey('address')) {
          await docRef.update({
            'addresses': [], // إنشاء حقل addresses كقائمة فارغة
            'address': FieldValue.delete(), // حذف حقل address القديم
          });
          user['addresses'] = []; // تحديث البيانات المحلية
        }

        setState(() {
          name = user['name'] ?? '';
          phoneNumber = user['phone'] ?? '';
          email = user['email'] ?? widget.email;
          gender = user['gender'] ?? '';
          addressCount = (user['addresses'] as List?)?.length ?? 0; // تحديث العداد

          if (user['birthDate'] != null && user['birthDate'] is Timestamp) {
            birthDate = (user['birthDate'] as Timestamp).toDate();
          }

          nameController.text = name;
          phoneController.text = phoneNumber;
          emailController.text = email;
        });
      } else {
        setState(() {
          email = widget.email;
          emailController.text = email;
          addressCount = 0; // لا توجد عناوين للمستخدم الجديد
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        email = widget.email;
        emailController.text = email;
        addressCount = 0;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() {
        isLoading = true;
      });

      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .get();

      Map<String, dynamic> updatedData = {
        'name': nameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'gender': gender,
        if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate!),
      };

      if (userSnapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userSnapshot.docs.first.id)
            .update(updatedData);
      } else {
        await FirebaseFirestore.instance.collection('users').add(updatedData);
      }

      setState(() {
        name = nameController.text;
        phoneNumber = phoneController.text;
        email = emailController.text;
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes saved successfully!')),
      );
    } catch (e) {
      print("Error saving data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != birthDate) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  PageRouteBuilder _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Account',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              if (isEditing) {
                _saveChanges();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
            child: Text(
              isEditing ? 'SAVE' : 'EDIT',
              style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Full name*', nameController),
            SizedBox(height: 16),
            _buildTextField('Mobile number*', phoneController),
            SizedBox(height: 16),
            _buildTextField('Email*', emailController),
            SizedBox(height: 16),
            _buildDateField(
              'Birth date*',
              birthDate != null ? DateFormat('dd/MM/yyyy').format(birthDate!) : '',
              suffixIcon: Icon(Icons.calendar_today, color: Colors.grey, size: 20),
              onTap: isEditing ? () => _selectDate(context) : null,
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  _createSlideRoute(ChangePasswordPage(email: widget.email)),
                );
              },
              child: _buildTextField('Password', null,
                  suffixIcon: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)),
            ),
            SizedBox(height: 16),
            Text(
              'Gender*',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isEditing
                        ? () {
                      setState(() {
                        gender = 'Male';
                      });
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gender == 'Male' ? Colors.blue[900] : Colors.white,
                      foregroundColor: gender == 'Male' ? Colors.white : Colors.black,
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Male', style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isEditing
                        ? () {
                      setState(() {
                        gender = 'Female';
                      });
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gender == 'Female' ? Colors.blue[900] : Colors.white,
                      foregroundColor: gender == 'Female' ? Colors.white : Colors.black,
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Female', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.location_on, color: Colors.blue),
              title: Text(
                'Saved Addresses',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$addressCount address${addressCount != 1 ? 'es' : ''}', // عرض العداد
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        AddressManagementPage(email: widget.email), // تمرير البريد الإلكتروني الصحيح
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;
                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);
                      return SlideTransition(position: offsetAnimation, child: child);
                    },
                    transitionDuration: Duration(milliseconds: 500),
                  ),
                ).then((_) {
                  // إعادة جلب البيانات لتحديث العداد
                  _fetchUserData();
                });
              },
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController? controller, {Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!, width: 2.0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: isEditing && controller != null
                    ? TextField(
                  controller: controller,
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
                    : Text(
                  controller != null
                      ? controller.text
                      : (label == 'Password' ? '********' : ''),
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
              ),
              if (suffixIcon != null) suffixIcon,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String value, {Widget? suffixIcon, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[700]!, width: 2.0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ),
                if (suffixIcon != null) suffixIcon,
              ],
            ),
          ),
        ),
      ],
    );
  }
}