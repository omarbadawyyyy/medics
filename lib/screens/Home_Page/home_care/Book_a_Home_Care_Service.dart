import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookHomeCareServicePage extends StatefulWidget {
  final String email;

  const BookHomeCareServicePage({Key? key, required this.email}) : super(key: key);

  @override
  _BookHomeCareServicePageState createState() => _BookHomeCareServicePageState();
}

class _BookHomeCareServicePageState extends State<BookHomeCareServicePage> {
  final _formKey = GlobalKey<FormState>();
  String? name, phone, area, service;
  bool isLoading = false;

  // دالة لتنظيف الحقول بعد الإرسال
  void _clearForm() {
    setState(() {
      name = null;
      phone = null;
      area = null;
      service = null;
      _formKey.currentState?.reset();
    });
  }

  // دالة لإرسال البيانات إلى Firestore مع إظهار رسالة
  Future<void> _submitBookingToFirestore() async {
    try {
      // إرسال البيانات إلى Firestore
      await FirebaseFirestore.instance
          .collection('booking_home_care')
          .doc(widget.email)
          .collection('bookings')
          .add({
        'name': name,
        'phone': phone,
        'area': area,
        'service': service,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // إظهار رسالة النجاح في Dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 30),
              const SizedBox(width: 8),
              Text(
                'تم استلام طلبك',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, curve: Curves.easeInOut), // Animate the Row widget
          content: Text(
            'سوف يتم التواصل معاك قريبًا',
            style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 300.ms, curve: Curves.easeInOut), // Animate the Text widget
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _clearForm();
                },
                child: Text(
                  'موافق',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, curve: Curves.easeInOut), // Animate the TextButton
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إرسال البيانات: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Book a Home Care Service',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logowhite.png',
                          height: 200,
                          width: 150,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'احجز رعاية طبية منزلية موثوقة',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ميدكس تعطي الاولوية لراحتكم وعافيتكم لمنحكم رعاية عالية الجودة في مكانكم',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.blue[800],
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 800.ms, curve: Curves.easeInOut).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'احجز الآن وتأكد من سلامتك وصحتك',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'الاسم',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: TextFormField(
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: 'أدخل اسمك',
                              hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال الاسم';
                              }
                              return null;
                            },
                            onChanged: (value) => name = value,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'رقم الهاتف',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: TextFormField(
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'أدخل رقم الهاتف',
                              hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[600]),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال رقم الهاتف';
                              }
                              if (!RegExp(r'^01[0-2,5][0-9]{8}$').hasMatch(value)) {
                                return 'الرجاء إدخال رقم هاتف صحيح';
                              }
                              return null;
                            },
                            onChanged: (value) => phone = value,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'المنطقة',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: area,
                            alignment: Alignment.centerRight,
                            decoration: InputDecoration(
                              hintText: 'اختر المنطقة',
                              hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey[600]),
                            ),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            items: const [
                              DropdownMenuItem(value: 'alexandria', child: Text('الإسكندرية')),
                              DropdownMenuItem(value: 'aswan', child: Text('أسوان')),
                              DropdownMenuItem(value: 'asyut', child: Text('أسيوط')),
                              DropdownMenuItem(value: 'ismailia', child: Text('الإسماعيلية')),
                              DropdownMenuItem(value: 'luxor', child: Text('الأقصر')),
                              DropdownMenuItem(value: 'red_sea', child: Text('البحر الأحمر')),
                              DropdownMenuItem(value: 'beheira', child: Text('البحيرة')),
                              DropdownMenuItem(value: 'giza', child: Text('الجيزة')),
                              DropdownMenuItem(value: 'dakahlia', child: Text('الدقهلية')),
                              DropdownMenuItem(value: 'suez', child: Text('السويس')),
                              DropdownMenuItem(value: 'sharqia', child: Text('الشرقية')),
                              DropdownMenuItem(value: 'gharbia', child: Text('الغربية')),
                              DropdownMenuItem(value: 'fayoum', child: Text('الفيوم')),
                              DropdownMenuItem(value: 'cairo', child: Text('القاهرة')),
                              DropdownMenuItem(value: 'qalyubia', child: Text('القليوبية')),
                              DropdownMenuItem(value: 'menoufia', child: Text('المنوفية')),
                              DropdownMenuItem(value: 'minya', child: Text('المنيا')),
                              DropdownMenuItem(value: 'new_valley', child: Text('الوادي الجديد')),
                              DropdownMenuItem(value: 'beni_suef', child: Text('بني سويف')),
                              DropdownMenuItem(value: 'port_said', child: Text('بورسعيد')),
                              DropdownMenuItem(value: 'south_sinai', child: Text('جنوب سيناء')),
                              DropdownMenuItem(value: 'damietta', child: Text('دمياط')),
                              DropdownMenuItem(value: 'sohag', child: Text('سوهاج')),
                              DropdownMenuItem(value: 'north_sinai', child: Text('شمال سيناء')),
                              DropdownMenuItem(value: 'qena', child: Text('قنا')),
                              DropdownMenuItem(value: 'kafr_el_sheikh', child: Text('كفر الشيخ')),
                              DropdownMenuItem(value: 'matrouh', child: Text('مطروح')),
                            ],
                            onChanged: (value) => setState(() => area = value),
                            validator: (value) {
                              if (value == null) {
                                return 'الرجاء اختيار المنطقة';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'الخدمة',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: service,
                            alignment: Alignment.centerRight,
                            decoration: InputDecoration(
                              hintText: 'اختر الخدمة',
                              hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.medical_services_outlined, color: Colors.grey[600]),
                            ),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            items: const [
                              DropdownMenuItem(value: 'doctor_visit', child: Text('دكتور زيارة')),
                              DropdownMenuItem(value: 'nursing', child: Text('خدمات التمريض')),
                              DropdownMenuItem(value: 'home_medical_lab', child: Text('خدمات طبية منزلية من مختبر')),
                              DropdownMenuItem(value: 'lab_tests', child: Text('تحاليل من مختبر')),
                              DropdownMenuItem(value: 'xray_doppler_dental', child: Text('اشعة X-RAY ودوبلر واسنان')),
                              DropdownMenuItem(value: 'physiotherapy', child: Text('علاج طبيعي')),
                              DropdownMenuItem(value: 'ambulance', child: Text('خدمات اسعاف مرضي')),
                            ],
                            onChanged: (value) => setState(() => service = value),
                            validator: (value) {
                              if (value == null) {
                                return 'الرجاء اختيار الخدمة';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => isLoading = true);
                                await _submitBookingToFirestore();
                                setState(() => isLoading = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: isLoading
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: Colors.white),
                                const SizedBox(width: 16),
                                Text(
                                  'جاري إرسال الطلب...',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(duration: 300.ms).scale(curve: Curves.easeInOut)
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'تأكيد',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 800.ms, curve: Curves.easeInOut).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/footer_image.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ).animate().fadeIn(duration: 800.ms, curve: Curves.easeInOut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}