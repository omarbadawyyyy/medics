import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medics/screens/Home_Page/pharmacy/payment_page.dart';
import 'package:medics/screens/Home_Page/pharmacy/paymob_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'medicine_database_helper.dart';

class CartPage extends StatefulWidget {
  final Map<String, int> addedProducts;
  final String selectedAddress;
  final Function(Map<String, int>) onUpdateProducts;
  final String email;

  const CartPage({
    required this.addedProducts,
    required this.selectedAddress,
    required this.onUpdateProducts,
    required this.email,
    Key? key,
  }) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  final double _deliveryFee = 5.0;
  String _selectedPaymentMethod = 'Cash on Delivery';
  final MedicineDatabaseHelper _dbHelper = MedicineDatabaseHelper();
  String? _savedCardToken;
  bool _isSubscribed = false;
  bool _isLoading = true;
  bool _isProcessingOrder = false;
  final TextEditingController _couponController = TextEditingController();
  double _couponDiscount = 0.0;

  @override
  void initState() {
    super.initState();
    print('Email received in CartPage: ${widget.email}');
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await _loadSubscriptionStatus();
    await _fetchCartItems();
    await _loadSavedCardToken();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadSavedCardToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedCardToken = prefs.getString('saved_card_token');
    });
  }

  Future<void> _loadSubscriptionStatus() async {
    if (widget.email.isEmpty) {
      print('Error: Email is empty, cannot load subscription status from Firestore');
      setState(() {
        _isSubscribed = false;
      });
      return;
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(widget.email)
          .get();
      setState(() {
        _isSubscribed = doc.exists && (doc['isSubscribed'] ?? false);
        print('Subscription Status Loaded from Firestore: $_isSubscribed');
      });
    } catch (e) {
      print('Error loading subscription status from Firestore: $e');
      setState(() {
        _isSubscribed = false;
      });
    }
  }

  Future<void> _fetchCartItems() async {
    List<Map<String, dynamic>> items = [];
    for (String medicineName in widget.addedProducts.keys) {
      Map<String, dynamic>? medicine = await _dbHelper.getMedicineByName(medicineName);
      if (medicine != null) {
        Map<String, dynamic> mutableMedicine = Map.from(medicine);
        mutableMedicine['quantity'] = widget.addedProducts[medicineName] ?? 0;
        double originalPrice = double.parse(mutableMedicine['price'].toString());
        mutableMedicine['originalPrice'] = originalPrice;
        mutableMedicine['price'] = _isSubscribed ? originalPrice * 0.84 : originalPrice;
        items.add(mutableMedicine);
        print('Item: ${mutableMedicine['name']}, Original: $originalPrice, Discounted: ${mutableMedicine['price']}');
      } else {
        print('Medicine not found in database: $medicineName');
      }
    }
    if (mounted) {
      setState(() {
        _cartItems = items;
      });
    }
  }

  double _calculateSubtotal() {
    double total = 0.0;
    for (var item in _cartItems) {
      total += (item['price'] as num) * (item['quantity'] as int);
    }
    return total;
  }

  double _calculateOriginalSubtotal() {
    double total = 0.0;
    for (var item in _cartItems) {
      total += (item['originalPrice'] as num) * (item['quantity'] as int);
    }
    return total;
  }

  double _calculateTotalPrice() {
    double subtotal = _calculateSubtotal();
    return subtotal + _deliveryFee - _couponDiscount;
  }

  double _calculateOriginalTotalPrice() {
    return _calculateOriginalSubtotal() + _deliveryFee;
  }

  void _removeItem(String medicineName) {
    setState(() {
      widget.addedProducts.remove(medicineName);
      _cartItems.removeWhere((item) => item['name'] == medicineName);
      widget.onUpdateProducts(widget.addedProducts);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$medicineName removed from cart')),
    );
  }

  void _updateQuantity(String medicineName, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        widget.addedProducts.remove(medicineName);
        _cartItems.removeWhere((item) => item['name'] == medicineName);
      } else {
        widget.addedProducts[medicineName] = newQuantity;
        _cartItems.firstWhere((item) => item['name'] == medicineName)['quantity'] = newQuantity;
      }
      widget.onUpdateProducts(widget.addedProducts);
    });
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text('Are you sure you want to remove all items from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.addedProducts.clear();
                  _cartItems.clear();
                  widget.onUpdateProducts(widget.addedProducts);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cart cleared')),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _applyCoupon() {
    String couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a coupon code')),
      );
      return;
    }

    // هنا ممكن تضيفي لوجيك التحقق من الكوبون (مثلاً من Firestore أو قاعدة بيانات)
    // للتجربة، هنفترض كوبون بسيط يعطي خصم 10%
    if (couponCode.toLowerCase() == 'discount10') {
      setState(() {
        _couponDiscount = _calculateSubtotal() * 0.10; // خصم 10%
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon applied! 10% discount')),
      );
    } else {
      setState(() {
        _couponDiscount = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid coupon code')),
      );
    }
    _couponController.clear();
  }

  void _confirmOrder() {
    if (widget.selectedAddress == 'No Address Selected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address first')),
      );
      return;
    }
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }
    _placeOrder();
  }

  void _placeOrder() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirm Order'),
              content: _isProcessingOrder
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.blue,
                  ).animate().fadeIn().scale(),
                  const SizedBox(height: 16),
                  const Text(
                    'Processing your order...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ).animate().fadeIn(),
                ],
              )
                  : Text(
                'Are you sure you want to place this order?\nPayment Method: $_selectedPaymentMethod',
              ),
              actions: _isProcessingOrder
                  ? []
                  : [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    setDialogState(() {
                      _isProcessingOrder = true;
                    });

                    if (_selectedPaymentMethod == 'Paymob Payment') {
                      if (_savedCardToken != null) {
                        await _payWithSavedCard();
                      } else {
                        await _processPaymobPayment();
                      }
                    } else {
                      await _completeOrder();
                    }

                    setDialogState(() {
                      _isProcessingOrder = false;
                    });
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveOrderToFirestore(double subtotal, double deliveryFee, double finalTotal, List<Map<String, dynamic>> cartItems) async {
    try {
      String username = 'Unknown User';
      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        var user = userSnapshot.docs.first.data();
        username = user['name'] ?? 'Unknown User';
      }

      List<Map<String, dynamic>> productsToSave = cartItems.map((item) {
        return {
          'name': item['name'],
          'quantity': item['quantity'],
          'price': item['price'],
          'imagePath': item['imagePath'] ?? '',
        };
      }).toList();

      final orderData = {
        'username': username,
        'email': widget.email,
        'products': productsToSave,
        'address': widget.selectedAddress,
        'status': 'Processing',
        'orderId': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'totalPrice': subtotal,
        'deliveryFee': deliveryFee,
        'finalTotal': finalTotal,
        'paymentMethod': _selectedPaymentMethod,
        'couponDiscount': _couponDiscount,
      };

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.email)
          .collection('userOrders')
          .add(orderData);
      print('Order saved to Firestore in userOrders sub-collection for email: ${widget.email}');

      await FirebaseFirestore.instance.collection('subscriptions').doc(widget.email).set({
        'isSubscribed': true,
      }, SetOptions(merge: true));
      print('Subscription saved to Firestore for email: ${widget.email}');
    } catch (e) {
      print('Error saving order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save order')),
      );
    }
  }

  Future<void> _payWithSavedCard() async {
    try {
      final paymobManager = PaymobManager();
      final success = await paymobManager.payWithToken(_savedCardToken!, _calculateTotalPrice());
      if (success) {
        await _completeOrder();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful with saved card!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed with saved card.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error with saved card: $e')),
      );
    }
  }

  Future<void> _processPaymobPayment() async {
    try {
      final paymobManager = PaymobManager();
      final paymentKey = await paymobManager.getPaymentKey(_calculateTotalPrice());

      final paymentSuccessful = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            totalAmount: _calculateTotalPrice(),
            paymentKey: paymentKey,
            onPaymentComplete: (success) {
              if (success) {
                _completeOrder();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment successful!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment failed.')),
                );
              }
            },
          ),
        ),
      );

      if (paymentSuccessful == true) {
        await _completeOrder();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    }
  }

  Future<void> _completeOrder() async {
    final double subtotal = _calculateSubtotal();
    final double deliveryFee = _deliveryFee;
    final double finalTotal = _calculateTotalPrice();
    final List<Map<String, dynamic>> cartItems = List.from(_cartItems);

    setState(() {
      widget.addedProducts.clear();
      _cartItems.clear();
      widget.onUpdateProducts(widget.addedProducts);
    });

    await _saveOrderToFirestore(subtotal, deliveryFee, finalTotal, cartItems);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed successfully with $_selectedPaymentMethod!')),
    );
    Navigator.pop(context, widget.addedProducts);
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    double originalPrice = item['originalPrice'] as double;
    double discountedPrice = item['price'] as double;

    return Slidable(
      key: Key(item['name']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _removeItem(item['name']),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        elevation: 4.0,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: item['imagePath'] != null && item['imagePath'].isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    item['imagePath'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
                    },
                  ),
                )
                    : const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    if (_isSubscribed) ...[
                      Text(
                        '\$${originalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '\$${discountedPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, color: Colors.green),
                      ),
                    ] else
                      Text(
                        '\$${originalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _updateQuantity(item['name'], item['quantity'] - 1),
                  ).animate().scale(),
                  Text('${item['quantity']}', style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () => _updateQuantity(item['name'], item['quantity'] + 1),
                  ).animate().scale(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              onPressed: _clearCart,
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
        },
        child: _isLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Loading your cart...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        )
            : _cartItems.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              // ملخص السلة
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items: ${_cartItems.length}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total: \$${(_calculateSubtotal() - _couponDiscount).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  return _buildCartItem(item);
                },
              ),
              Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // قسم الكوبون
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            decoration: InputDecoration(
                              labelText: 'Enter Coupon Code',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _applyCoupon,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('Subtotal:', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_isSubscribed) ...[
                              Text(
                                '\$${_calculateOriginalSubtotal().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '\$${_calculateSubtotal().toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16, color: Colors.green),
                              ),
                              const Text(
                                '16% discount applied (Shamel subscription)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ] else
                              Text(
                                '\$${_calculateSubtotal().toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_couponDiscount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.discount, color: Colors.grey, size: 20),
                              SizedBox(width: 8),
                              Text('Coupon Discount:', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          Text(
                            '-\$${_couponDiscount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, color: Colors.green),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_shipping, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('Delivery Fee:', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Text(
                          '\$${_deliveryFee.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.monetization_on, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Total:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_isSubscribed) ...[
                              Text(
                                '\$${_calculateOriginalTotalPrice().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '\$${_calculateTotalPrice().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text(
                                '16% discount applied (Shamel subscription)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ] else
                              Text(
                                '\$${_calculateTotalPrice().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('Delivery Address:', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Flexible(
                          child: Text(
                            widget.selectedAddress,
                            style: const TextStyle(fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    const Text(
                      'Payment Method:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Cash on Delivery',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                        const Icon(Icons.money, color: Colors.green),
                        const SizedBox(width: 5),
                        const Text('Cash on Delivery'),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Paymob Payment',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                        const Icon(Icons.payment, color: Colors.purple),
                        const SizedBox(width: 5),
                        const Text('Paymob Payment'),
                      ],
                    ),
                    if (_savedCardToken != null && _selectedPaymentMethod == 'Paymob Payment')
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Using saved card',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Place Order',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ).animate().fadeIn().scale(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }
}