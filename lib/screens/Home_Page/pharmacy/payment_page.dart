import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // إضافة SharedPreferences
import 'package:medics/screens/Home_Page/pharmacy/paymob_manager.dart'; // استيراد PaymobManager

class PaymentPage extends StatefulWidget {
  final double totalAmount; // Total amount in dollars
  final String paymentKey;
  final Function(bool) onPaymentComplete;

  const PaymentPage({
    required this.totalAmount,
    required this.paymentKey,
    required this.onPaymentComplete,
    Key? key,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late WebViewController _controller;
  bool _isLoading = true; // Track WebView loading state
  bool _saveCard = false; // متغير جديد لتتبع اختيار حفظ البطاقة

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true; // Show loading when page starts
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false; // Hide loading when page finishes
            });
            if (url.contains('success') || url.contains('completed')) {
              _handlePaymentResult(true); // استدعاء دالة جديدة لمعالجة النتيجة
            } else if (url.contains('failed') || url.contains('error')) {
              _handlePaymentResult(false); // استدعاء دالة جديدة لمعالجة النتيجة
            }
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false; // Hide loading on error
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading payment page: ${error.description}')),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://accept.paymob.com/api/acceptance/iframes/909420?payment_token=${widget.paymentKey}'));
  }

  // دالة جديدة لمعالجة نتيجة الدفع وحفظ الـ Token إذا لزم الأمر
  void _handlePaymentResult(bool success) async {
    if (success && _saveCard) {
      try {
        final paymobManager = PaymobManager();
        final cardToken = await paymobManager.getCardToken(widget.paymentKey);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_card_token', cardToken);
      } catch (e) {
        print('Error saving card token: $e');
      }
    }
    widget.onPaymentComplete(success);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paymob Payment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0, // Flat design
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Allow manual back navigation
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[100]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // WebView
            WebViewWidget(controller: _controller),
            // Loading Indicator
            if (_isLoading)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Processing Payment of \$${widget.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.blueAccent.withOpacity(0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _saveCard,
                  onChanged: (value) {
                    setState(() {
                      _saveCard = value ?? false;
                    });
                  },
                  activeColor: Colors.blueAccent,
                ),
                const Text(
                  'Save card for future payments',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, color: Colors.blueAccent, size: 16),
                const SizedBox(width: 5),
                Text(
                  'Secured by Paymob',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
