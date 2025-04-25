import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

class MapPickerPage extends StatefulWidget {
  final String email;

  const MapPickerPage({required this.email, Key? key}) : super(key: key);

  @override
  _MapPickerPageState createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();
  latlong.LatLng _currentPosition = const latlong.LatLng(30.0444, 31.2357); // Default location (Cairo)
  String _address = "Loading address...";
  bool _isLoading = true;
  bool _isLocating = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLocating = true;
      });

      print("Checking if location services are enabled...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print("Location services enabled: $serviceEnabled");

      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        setState(() {
          _isLocating = false;
        });
        return;
      }

      print("Checking location permissions...");
      LocationPermission permission = await Geolocator.checkPermission();
      print("Permission status: $permission");

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print("Permission after request: $permission");
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          setState(() {
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied.')),
          );
        }
        setState(() {
          _isLocating = false;
        });
        return;
      }

      print("Fetching current position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("Position: ${position.latitude}, ${position.longitude}");

      setState(() {
        _currentPosition = latlong.LatLng(position.latitude, position.longitude);
        _mapController.move(_currentPosition, 15.0);
      });

      await _updateAddress(_currentPosition);
    } catch (e) {
      print("Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting current location: $e')),
        );
      }
      await _updateAddress(_currentPosition);
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _updateAddress(latlong.LatLng position) async {
    try {
      print("Fetching address for coordinates: ${position.latitude}, ${position.longitude}");
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String country = place.country ?? "Unknown Country";
        String governorate = place.administrativeArea ?? "Unknown Governorate";
        String city = place.locality ?? place.subLocality ?? "Unknown City";
        String details = place.street ?? "Unknown Street";

        setState(() {
          _address = "$details, $city, $governorate, $country";
          _isLoading = false;
        });
      } else {
        _retryOrFallback(position);
      }
    } catch (e) {
      print("Error fetching address: $e");
      _retryOrFallback(position);
    }
  }

  Future<void> _retryOrFallback(latlong.LatLng position) async {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      print("Retry $_retryCount of $_maxRetries for fetching address...");
      await Future.delayed(const Duration(seconds: 2)); // Delay before retry
      await _updateAddress(position);
    } else {
      setState(() {
        _address = "Unable to fetch address (Approx: Cairo, Egypt)";
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (_isLoading) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait until the address is loaded.')),
        );
      }
      return;
    }

    Map<String, dynamic> address = {
      'country': _address.split(", ").last,
      'governorate': _address.split(", ")[2],
      'city': _address.split(", ")[1],
      'details': _address.split(", ")[0],
    };

    try {
      setState(() {
        _isLoading = true;
      });

      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        var userDoc = userSnapshot.docs.first;
        var docRef = userDoc.reference;

        if (userDoc.data().containsKey('address')) {
          await docRef.update({
            'addresses': [],
            'address': FieldValue.delete(),
          });
        }

        await docRef.update({
          'addresses': FieldValue.arrayUnion([address]),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address saved successfully!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        await FirebaseFirestore.instance.collection('users').add({
          'email': widget.email,
          'addresses': [address],
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address saved successfully!')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print("Error saving address: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          'Pick Address from Map',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _currentPosition = position.center!;
                  });
                  _updateAddress(_currentPosition);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    child: const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _address,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Save Address',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLocating ? null : _getCurrentLocation,
        backgroundColor: Colors.blue[900],
        child: _isLocating
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}