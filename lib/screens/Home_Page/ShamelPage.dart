import 'package:flutter/material.dart';
import 'package:medics/screens/Home_Page/pharmacy/paymob_manager.dart';
import 'package:medics/screens/Home_Page/pharmacy/payment_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ShamelPage extends StatefulWidget {
  final String email;
  const ShamelPage({Key? key, required this.email}) : super(key: key);

  @override
  _ShamelPageState createState() => _ShamelPageState();
}

class _ShamelPageState extends State<ShamelPage> {
  bool _isSubscribed = false;
  bool _isLoadingPayment = false;
  bool _isLoadingCancel = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(widget.email)
          .get();
      setState(() {
        _isSubscribed = doc.exists && (doc['isSubscribed'] ?? false);
      });
    } catch (e) {
      print('Error loading subscription status: $e');
    }
  }

  Future<void> _saveSubscriptionStatus(bool status) async {
    try {
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(widget.email)
          .set({'isSubscribed': status});
      setState(() {
        _isSubscribed = status;
      });
    } catch (e) {
      print('Error saving subscription status: $e');
    }
  }

  double _applyDiscount(double originalPrice) {
    if (_isSubscribed) {
      return originalPrice * 0.6;
    }
    return originalPrice;
  }

  Future<void> _navigateToPaymentPage(BuildContext context) async {
    setState(() {
      _isLoadingPayment = true;
    });

    try {
      final paymobManager = PaymobManager();
      final paymentKey = await paymobManager.getPaymentKey(800.0);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            totalAmount: 800.0,
            paymentKey: paymentKey,
            onPaymentComplete: (success) {
              if (success) {
                _saveSubscriptionStatus(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment Successful!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment Failed!')),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initiating payment: $e')),
      );
    } finally {
      setState(() {
        _isLoadingPayment = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    setState(() {
      _isLoadingCancel = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    await _saveSubscriptionStatus(false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription Cancelled!')),
    );

    setState(() {
      _isLoadingCancel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color listBackgroundColor =
    _isSubscribed ? const Color(0xFFCAAD0C) : Colors.white;
    final Color buttonColor =
    _isSubscribed ? const Color(0xFF937E0A) : Colors.blue[900]!;

    const double originalPrice = 1000.0;
    final double discountedPrice = _applyDiscount(originalPrice);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF6FF),
        elevation: 0,
        title: const Text(
          'Shamel',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSubscribed)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'You have subscribed to all the following services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _isSubscribed
                    ? 'Example Product: Original Price: $originalPrice EGP\nAfter 40% Discount: $discountedPrice EGP'
                    : 'Example Product: Original Price: $originalPrice EGP\nSubscribe to get 40% discount!',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: listBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2.0),
                ),
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Individual Plan',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '800 EGP/Year',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: buttonColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildListItem(
                      icon: Icons.person_outline,
                      text: '1 User',
                      textColor: Colors.black87,
                    ),
                    const Divider(),
                    _buildListItem(
                      icon: Icons.account_balance_wallet_outlined,
                      text: 'You will save on average 9,470 EGP/Year',
                      textColor: Colors.green[700]!,
                    ),
                    const Divider(),
                    _buildListItem(
                      icon: Icons.medical_services_outlined,
                      text: 'Up to 40% discounts on Consultations & Services',
                      textColor: Colors.black87,
                    ),
                    const Divider(),
                    _buildListItem(
                      icon: Icons.local_hospital_outlined,
                      text: 'Up to 80% discounts on Labs and Scans',
                      textColor: Colors.black87,
                    ),
                    const Divider(),
                    _buildListItem(
                      icon: Icons.local_hospital,
                      text: 'Discounted ALL inclusive prices for operations',
                      textColor: Colors.black87,
                    ),
                    const Divider(),
                    _buildListItem(
                      icon: Icons.medical_information_outlined,
                      text: 'Up to 16% discounts on Pharmacy Supplies',
                      textColor: Colors.black87,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubscribed
                    ? null
                    : () => _navigateToPaymentPage(context),
                child: _isLoadingPayment
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  _isSubscribed ? 'Subscribed' : 'Get Started',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (_isSubscribed) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoadingCancel ? null : _cancelSubscription,
                  child: _isLoadingCancel
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Cancel Subscription',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String text,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontWeight: text == 'You will save on average 9,470 EGP/Year'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
