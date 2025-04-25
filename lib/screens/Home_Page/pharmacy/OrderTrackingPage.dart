import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ

class OrderTrackingPage extends StatefulWidget {
  final String email;
  final Function(int) onOrderCountChanged;

  const OrderTrackingPage({
    required this.email,
    required this.onOrderCountChanged,
    Key? key,
  }) : super(key: key);

  @override
  _OrderTrackingPageState createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final Map<String, bool> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    print('Email used: ${widget.email}');
  }

  // دالة لتحديد لون الحالة
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Processing':
        return Colors.orange;
      case 'Shipped':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // دالة لإلغاء الطلب مع رسالة تأكيد وحذف الطلبية
  Future<void> _cancelOrder(String orderId) async {
    // إظهار رسالة تأكيد
    bool? confirmCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // المستخدم رفض الإلغاء
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // المستخدم أكد الإلغاء
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    // لو المستخدم أكد الإلغاء
    if (confirmCancel == true) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.email)
            .collection('userOrders')
            .doc(orderId)
            .delete(); // حذف الطلبية نهائيًا
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete order: $e')),
        );
      }
    }
  }

  // دالة لتنسيق التاريخ
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final dateTime = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Orders'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh البيانات
          setState(() {});
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.email)
              .collection('userOrders')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Loading orders...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading orders: ${snapshot.error}',
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onOrderCountChanged(0);
              });
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No orders found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final orders = snapshot.data!.docs;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onOrderCountChanged(orders.length);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final orderDoc = orders[index];
                final order = orderDoc.data() as Map<String, dynamic>;
                final orderId = order['orderId'] ?? 'Unknown';
                final status = order['status'] ?? 'Unknown';
                final address = order['address'] ?? 'No address';
                final products = List<Map<String, dynamic>>.from(order['products'] ?? []);
                final subtotalPrice = order['totalPrice']?.toStringAsFixed(2) ?? '0.00';
                final deliveryFee = order['deliveryFee']?.toStringAsFixed(2) ?? '0.00';
                final finalTotal = order['finalTotal']?.toStringAsFixed(2) ?? '0.00';
                final paymentMethod = order['paymentMethod'] ?? 'Unknown';
                final username = order['username'] ?? 'Unknown User';
                final timestamp = order['timestamp'] as Timestamp?;
                final isExpanded = _expandedOrders[orderId] ?? false;

                return Card(
                  elevation: 5.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header مع Expand/Collapse
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _expandedOrders[orderId] = !isExpanded;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt, color: Colors.blue, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Order #$orderId',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ordered by: $username',
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Placed on: ${_formatTimestamp(timestamp)}',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.local_shipping, color: _getStatusColor(status), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Status: $status',
                              style: TextStyle(fontSize: 16, color: _getStatusColor(status), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (isExpanded) ...[
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Delivery Address: $address',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Products:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...products.map((product) => Card(
                            elevation: 2.0,
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: product['imagePath'] != null && product['imagePath'].isNotEmpty
                                        ? Image.asset(
                                      product['imagePath'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.broken_image, size: 30, color: Colors.grey);
                                      },
                                    )
                                        : const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'],
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Quantity: ${product['quantity']}',
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                        Text(
                                          'Price: \$${product['price'].toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$$subtotalPrice',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Delivery Fee:',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '\$$deliveryFee',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$$finalTotal',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.payment, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Payment Method: $paymentMethod',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildStatusTimeline(status),
                          const SizedBox(height: 12),
                          // أزرار الإجراءات
                          if (status == 'Processing') ...[
                            Center(
                              child: ElevatedButton(
                                onPressed: () => _cancelOrder(orderDoc.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text(
                                  'Cancel Order',
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(String status) {
    final statuses = ['Processing', 'Shipped', 'Delivered'];
    final currentIndex = statuses.indexOf(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(statuses.length, (index) {
        return Row(
          children: [
            Column(
              children: [
                Icon(
                  index <= currentIndex ? Icons.check_circle : Icons.circle_outlined,
                  color: index <= currentIndex ? Colors.green : Colors.grey,
                  size: 24,
                ),
                if (index < statuses.length - 1)
                  Container(
                    height: 30,
                    width: 2,
                    color: index < currentIndex ? Colors.green : Colors.grey,
                  ),
              ],
            ),
            const SizedBox(width: 16.0),
            Text(
              statuses[index],
              style: TextStyle(
                fontSize: 16,
                fontWeight: index <= currentIndex ? FontWeight.bold : FontWeight.normal,
                color: index <= currentIndex ? Colors.black : Colors.grey,
              ),
            ),
          ],
        );
      }),
    );
  }
}
