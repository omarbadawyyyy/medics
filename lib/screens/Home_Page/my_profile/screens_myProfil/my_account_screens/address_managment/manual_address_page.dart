import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManualAddressPage extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? initialAddress; // للتعديل

  ManualAddressPage({required this.email, this.initialAddress});

  @override
  _ManualAddressPageState createState() => _ManualAddressPageState();
}

class _ManualAddressPageState extends State<ManualAddressPage> {
  String? selectedCountry;
  String? selectedGovernorate;
  String? selectedCity;
  final _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // قوائم الدول والمحافظات والمدن مرتبة أبجديًا
  final List<String> countries = ['Egypt', 'Saudi Arabia']..sort();

  final Map<String, List<String>> governorates = {
    'Egypt': [
      'Alexandria',
      'Aswan',
      'Assiut',
      'Beheira',
      'Beni Suef',
      'Cairo',
      'Dakahlia',
      'Damietta',
      'Faiyum',
      'Gharbia',
      'Giza',
      'Ismailia',
      'Kafr El Sheikh',
      'Luxor',
      'Matrouh',
      'Minya',
      'Monufia',
      'New Valley',
      'North Sinai',
      'Port Said',
      'Qalyubia',
      'Qena',
      'Red Sea',
      'Sharqia',
      'Sohag',
      'South Sinai',
      'Suez'
    ]..sort(),
    'Saudi Arabia': [
      'Al-Baha',
      'Al-Jawf',
      'Asir',
      'Eastern Province',
      'Hail',
      'Jazan',
      'Makkah',
      'Medina',
      'Najran',
      'Northern Borders',
      'Qassim',
      'Riyadh',
      'Tabuk'
    ]..sort(),
  };

  final Map<String, List<String>> cities = {
    // Egypt Governorates
    'Alexandria': ['Alexandria', 'Moharram Bek', 'Montaza', 'Sidi Gaber']..sort(),
    'Aswan': ['Aswan', 'Edfu', 'Kom Ombo']..sort(),
    'Assiut': ['Assiut', 'Dayrout', 'Manfalut']..sort(),
    'Beheira': ['Damanhur', 'Kafr El Dawwar', 'Rashid']..sort(),
    'Beni Suef': ['Beni Suef', 'Nasser', 'Wasta']..sort(),
    'Cairo': ['Cairo', 'Heliopolis', 'Maadi', 'Nasr City']..sort(),
    'Dakahlia': ['Mansoura', 'Mit Ghamr', 'Talkha']..sort(),
    'Damietta': ['Damietta', 'Kafr Saad', 'Ras El Bar']..sort(),
    'Faiyum': ['Faiyum', 'Sinnuris', 'Tamiya']..sort(),
    'Gharbia': ['Tanta', 'Mahalla El Kubra', 'Zefta']..sort(),
    'Giza': ['6th of October', 'Giza', 'Pyramids', 'Sheikh Zayed']..sort(),
    'Ismailia': ['Ismailia', 'Fayed', 'Qantara']..sort(),
    'Kafr El Sheikh': ['Kafr El Sheikh', 'Desouk', 'Fowa']..sort(),
    'Luxor': ['Luxor', 'Armant', 'Esna']..sort(),
    'Matrouh': ['Marsa Matrouh', 'Siwa', 'El Alamein']..sort(),
    'Minya': ['Minya', 'Mallawi', 'Samalut']..sort(),
    'Monufia': ['Shebin El Kom', 'Menouf', 'Sadat City']..sort(),
    'New Valley': ['Kharga', 'Dakhla', 'Farafra']..sort(),
    'North Sinai': ['Arish', 'Rafah', 'Sheikh Zuweid']..sort(),
    'Port Said': ['Port Said', 'Port Fouad']..sort(),
    'Qalyubia': ['Banha', 'Qalyub', 'Shubra El Kheima']..sort(),
    'Qena': ['Qena', 'Nag Hammadi', 'Qus']..sort(),
    'Red Sea': ['Hurghada', 'Safaga', 'Marsa Alam']..sort(),
    'Sharqia': ['Zagazig', 'Bilbeis', 'Minya El Qamh']..sort(),
    'Sohag': ['Sohag', 'Akhmim', 'Tahta']..sort(),
    'South Sinai': ['Sharm El Sheikh', 'Dahab', 'Nuweiba']..sort(),
    'Suez': ['Suez', 'Arbaeen', 'Ganayen']..sort(),
    // Saudi Arabia Regions
    'Al-Baha': ['Al-Baha', 'Baljurashi', 'Al-Mandaq']..sort(),
    'Al-Jawf': ['Sakakah', 'Dumat Al-Jandal', 'Qurayyat']..sort(),
    'Asir': ['Abha', 'Khamis Mushait', 'Bisha']..sort(),
    'Eastern Province': ['Dammam', 'Khobar', 'Dhahran']..sort(),
    'Hail': ['Hail', 'Baqaa', 'Al-Shinan']..sort(),
    'Jazan': ['Jazan', 'Sabya', 'Abu Arish']..sort(),
    'Makkah': ['Jeddah', 'Makkah', 'Taif']..sort(),
    'Medina': ['Medina', 'Yanbu', 'Al Ula']..sort(),
    'Najran': ['Najran', 'Sharurah', 'Habuna']..sort(),
    'Northern Borders': ['Arar', 'Rafha', 'Turaif']..sort(),
    'Qassim': ['Buraidah', 'Unaizah', 'Al-Rass']..sort(),
    'Riyadh': ['Al Olaya', 'Al Rajhi', 'Diriyah', 'Riyadh']..sort(),
    'Tabuk': ['Tabuk', 'Umluj', 'Duba']..sort(),
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      selectedCountry = widget.initialAddress!['country'];
      selectedGovernorate = widget.initialAddress!['governorate'];
      selectedCity = widget.initialAddress!['city'];
      _detailsController.text = widget.initialAddress!['details'];
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      if (selectedCountry == null ||
          selectedGovernorate == null ||
          selectedCity == null ||
          _detailsController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields!')),
        );
        return;
      }

      Map<String, dynamic> address = {
        'country': selectedCountry,
        'governorate': selectedGovernorate,
        'city': selectedCity,
        'details': _detailsController.text,
      };

      try {
        var userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: widget.email)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var userDoc = userSnapshot.docs.first;
          List<dynamic> currentAddresses =
          List<Map<String, dynamic>>.from(userDoc['addresses'] ?? []);
          int indexToUpdate = -1;
          if (widget.initialAddress != null) {
            indexToUpdate = currentAddresses.indexWhere(
                    (addr) => addr['details'] == widget.initialAddress!['details']);
          }
          if (indexToUpdate >= 0) {
            currentAddresses[indexToUpdate] = address;
          } else {
            currentAddresses.add(address);
          }
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .update({'addresses': currentAddresses});

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Address ${widget.initialAddress == null ? 'saved' : 'updated'} successfully!')),
          );
          Navigator.pop(context, true); // إرجاع true لتحديث القائمة
        } else {
          await FirebaseFirestore.instance.collection('users').add({
            'email': widget.email,
            'addresses': [address],
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Address saved successfully!')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Address', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Country',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCountry,
                  hint: Text('Choose a country'),
                  items: countries.map((String country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCountry = value;
                      selectedGovernorate = null;
                      selectedCity = null;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  validator: (value) =>
                  value == null ? 'Please select a country' : null,
                ),
                SizedBox(height: 16),
                if (selectedCountry != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Governorate',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedGovernorate,
                        hint: Text('Choose a governorate'),
                        items: governorates[selectedCountry]!
                            .map((String governorate) {
                          return DropdownMenuItem<String>(
                            value: governorate,
                            child: Text(governorate),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGovernorate = value;
                            selectedCity = null;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        validator: (value) =>
                        value == null ? 'Please select a governorate' : null,
                      ),
                    ],
                  ),
                if (selectedGovernorate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      Text('Select City',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedCity,
                        hint: Text('Choose a city'),
                        items: cities[selectedGovernorate]?.map((String city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          );
                        })?.toList() ?? [],
                        onChanged: (value) => setState(() => selectedCity = value),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        validator: (value) =>
                        value == null ? 'Please select a city' : null,
                      ),
                    ],
                  ),
                if (selectedCity != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      Text('Address Details',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _detailsController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: 'Enter detailed address',
                        ),
                        maxLines: 3,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter address details'
                            : null,
                      ),
                    ],
                  ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child:
                  Text('Save Address', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
