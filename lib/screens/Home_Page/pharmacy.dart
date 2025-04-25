import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // استيراد مكتبة URL Launcher
import 'package:image_picker/image_picker.dart'; // استيراد مكتبة Image Picker

class PharmacyPage extends StatefulWidget {
  @override
  _PharmacyPageState createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker(); // مكون التقاط الصور
  String _resultMessage = '';

  final List<Widget> _pages = [
    Center(child: Text("Welcome to the Pharmacy Page!")),
    Center(child: Text("Another Page")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0) {
        Navigator.pop(context);
      } else {
        _selectedIndex = index;
      }
    });
  }

  // دالة لفتح تطبيق الاتصال بالرقم المحدد
  void _makePhoneCall() async {
    final phoneNumber = '16676';
    final url = 'tel:$phoneNumber';
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch the dialer.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  // دالة لفتح الكاميرا أو اختيار صورة من المعرض
  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera); // فتح الكاميرا
    if (image != null) {
      setState(() {
        _resultMessage = 'Image selected: ${image.path}';
      });
    } else {
      setState(() {
        _resultMessage = 'No image selected';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // الجزء العلوي
          Container(
            padding: EdgeInsets.all(20.0),
            color: Colors.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان "Deliver to" مع النص أسفله في المنتصف أفقيًا
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Deliver to',
                          style: TextStyle(color: Colors.white, fontSize: 22.0),
                        ),
                        Text(
                          'No Address Selected',
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 15.0),
                // مربع البحث (رجاعه للعرض الكامل)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'What are you looking for?',
                      hintStyle: TextStyle(fontSize: 12.0),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, size: 18.0),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                // الأزرار تحت مربع البحث
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton('Prescription or Claim', Icons.local_pharmacy, 60.0),
                    _buildButton('Product Picture', Icons.camera_alt, 87.0, onTap: _pickImage),
                    _buildButton('Pharmacist Assistance', Icons.phone, 60.0, onTap: _makePhoneCall),
                  ],
                ),
              ],
            ),
          ),
          // باقي محتوى الصفحة
          Expanded(
            child: _pages[_selectedIndex],
          ),
          // عرض نتيجة اختيار الصورة
          if (_resultMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(_resultMessage, style: TextStyle(fontSize: 16.0)),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'My Activity',
          ),
        ],
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  // دالة لبناء الأزرار مع ارتفاع مخصص
  Widget _buildButton(String label, IconData icon, double buttonHeight, {VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, // الخلفية البيضاء
            minimumSize: Size(0, buttonHeight),
            padding: EdgeInsets.symmetric(vertical: 10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            side: BorderSide(color: Colors.blue), // تحديد حدود الزر باللون الأزرق
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue, size: 28.0),
              SizedBox(height: 5.0),
              Text(
                label,
                style: TextStyle(color: Colors.blue, fontSize: 12.0),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
