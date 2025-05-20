import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../home_care/Doctor_visit.dart';
import 'manual_address_page.dart';
import 'map_picker_page.dart';

class AddressManagementPage extends StatefulWidget {
  final String email;
  final String? source;
  final String? specialty; // إضافة specialty

  const AddressManagementPage({
    required this.email,
    this.source,
    this.specialty,
  });

  @override
  _AddressManagementPageState createState() => _AddressManagementPageState();
}

class _AddressManagementPageState extends State<AddressManagementPage> {
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
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
        setState(() {
          addresses = List<Map<String, dynamic>>.from(user['addresses'] ?? []);
        });
      }
    } catch (e) {
      print("Error fetching addresses: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching addresses: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _editAddress(int index) async {
    var address = addresses[index];
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ManualAddressPage(
          email: widget.email,
          initialAddress: address,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
    if (result == true) _fetchAddresses();
  }

  Future<void> _deleteAddress(int index) async {
    try {
      bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this address?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        var docRef = userSnapshot.docs.first.reference;

        setState(() {
          addresses.removeAt(index);
        });

        await docRef.update({
          'addresses': addresses,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted successfully')),
        );
      }
    } catch (e) {
      print("Error deleting address: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting address: $e')),
      );
      _fetchAddresses();
    }
  }

  void _selectAddress(int index) {
    if (widget.source == 'doctor_visit') {
      var address = addresses[index];
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => DoctorVisitPage(
            email: widget.email,
            selectedAddress: address,
            specialty: widget.specialty ?? 'General', // تمرير specialty مع fallback
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Addresses',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchAddresses,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Address',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  leading: Icon(Icons.edit, color: Colors.blue[900], size: 30),
                  title: const Text(
                    'Enter Address Manually',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ManualAddressPage(email: widget.email),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;
                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);
                          return SlideTransition(position: offsetAnimation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 500),
                      ),
                    );
                    if (result == true) _fetchAddresses();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  leading: Icon(Icons.map, color: Colors.blue[900], size: 30),
                  title: const Text(
                    'Pick Address from Map',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            MapPickerPage(email: widget.email),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;
                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);
                          return SlideTransition(position: offsetAnimation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 500),
                      ),
                    );
                    if (result == true) _fetchAddresses();
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Saved Addresses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: addresses.isEmpty
                    ? const Center(child: Text('No saved addresses yet'))
                    : ListView.builder(
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    var address = addresses[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          '${address['details']}, ${address['city']}, ${address['governorate']}, ${address['country']}',
                          style: const TextStyle(fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectAddress(index),
                        trailing: widget.source == 'doctor_visit'
                            ? null
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue[900]),
                              onPressed: () => _editAddress(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAddress(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}