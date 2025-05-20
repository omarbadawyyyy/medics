import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'OrderTrackingPage.dart';
import 'cartPage.dart';
import 'medicine_database_helper.dart';
import '../my_profile/screens_myProfil/my_account_screens/address_managment/address_management_page.dart';

class PharmacyPage extends StatefulWidget {
  final String email;

  const PharmacyPage({required this.email, Key? key}) : super(key: key);

  @override
  _PharmacyPageState createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _pickedImagePath;
  Map<String, dynamic>? _selectedMedicine;
  final MedicineDatabaseHelper _dbHelper = MedicineDatabaseHelper();

  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allMedicines = [];
  List<Map<String, dynamic>> _displayedMedicines = [];
  int _itemsPerPage = 10;
  int _currentPage = 0;
  bool _isContentLoading = true;

  static String _selectedAddress = 'No Address Selected';
  static Map<String, int> _addedProducts = {};
  List<Map<String, dynamic>> _addresses = [];

  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPageAds = 0;
  final List<String> _adImages = const [
    'assets/ad1.jpg',
    'assets/ad2.jpg',
    'assets/ad3.jpg',
  ];

  int _orderCount = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _startAutoSwitch();
    _searchController.addListener(_onSearchTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContentWithDelay();
    });
  }

  Future<void> _loadContentWithDelay() async {
    setState(() => _isContentLoading = true);
    await Future.wait([
      Future.delayed(const Duration(seconds: 1), () async {
        await _initializeDatabase();
        await _fetchAddressesFromFirebase();
        await _fetchAllMedicines();
        _loadMoreMedicines();
      }),
    ]);
    if (mounted) {
      setState(() => _isContentLoading = false);
    }
  }

  Future<void> _initializeDatabase() async {
    await _dbHelper.addMedicines();
  }

  Future<void> _fetchAllMedicines() async {
    final medicines = await _dbHelper.getAllMedicines();
    if (mounted) {
      setState(() {
        _allMedicines = medicines;
      });
    }
  }

  void _loadMoreMedicines() {
    if (_allMedicines.isEmpty) return;

    int startIndex = _currentPage * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _allMedicines.length) return;

    endIndex = endIndex > _allMedicines.length ? _allMedicines.length : endIndex;

    setState(() {
      _displayedMedicines.addAll(_allMedicines.sublist(startIndex, endIndex));
      _currentPage++;
    });
  }

  Future<void> _fetchAddressesFromFirebase() async {
    try {
      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.email)
          .get();

      if (userSnapshot.docs.isNotEmpty && mounted) {
        var user = userSnapshot.docs.first.data();
        setState(() {
          _addresses = List<Map<String, dynamic>>.from(user['addresses'] ?? []);
        });
      }
    } catch (e) {
      print("Error fetching addresses: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load addresses')),
        );
      }
    }
  }

  String _shortenAddress(String fullAddress) {
    List<String> words = fullAddress.split(' ');
    if (words.length <= 3) return fullAddress;
    return '${words.take(3).join(' ')}...';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _makePhoneCall() async {
    const phoneNumber = '16676';
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch the dialer')),
      );
    }
  }

  void _showImageSourceDialog({required Function(String) onImagePicked}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double dialogWidth = constraints.maxWidth * 0.85;
                double dialogHeight = constraints.maxHeight * 0.5;
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20 * constraints.maxWidth / 360)),
                  backgroundColor: Colors.white,
                  contentPadding: EdgeInsets.all(16 * constraints.maxWidth / 360),
                  content: SizedBox(
                    width: dialogWidth,
                    height: dialogHeight,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Lottie.asset(
                            'assets/animation/loader.json',
                            height: dialogHeight * 0.3,
                            width: dialogWidth * 0.3,
                          ),
                          SizedBox(height: 16 * constraints.maxHeight / 640),
                          Text(
                            'Select Image Source',
                            style: TextStyle(
                              fontSize: 20 * constraints.maxWidth / 360,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8 * constraints.maxHeight / 640),
                          Text(
                            'Choose where to get the image from:',
                            style: TextStyle(
                              fontSize: 16 * constraints.maxWidth / 360,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16 * constraints.maxHeight / 640),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                                  if (image != null) {
                                    onImagePicked(image.path);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No image selected')),
                                    );
                                  }
                                },
                                icon: Icon(Icons.camera_alt, size: 20 * constraints.maxWidth / 360),
                                label: Text(
                                  'Camera',
                                  style: TextStyle(fontSize: 14 * constraints.maxWidth / 360),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12 * constraints.maxWidth / 360),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16 * constraints.maxWidth / 360,
                                    vertical: 12 * constraints.maxHeight / 640,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                  if (image != null) {
                                    onImagePicked(image.path);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No image selected')),
                                    );
                                  }
                                },
                                icon: Icon(Icons.photo_library, size: 20 * constraints.maxWidth / 360),
                                label: Text(
                                  'Gallery',
                                  style: TextStyle(fontSize: 14 * constraints.maxWidth / 360),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12 * constraints.maxWidth / 360),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16 * constraints.maxWidth / 360,
                                    vertical: 12 * constraints.maxHeight / 640,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16 * constraints.maxWidth / 360,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _pickImage() {
    _showImageSourceDialog(
      onImagePicked: (imagePath) async {
        setState(() {
          _pickedImagePath = imagePath;
          _isLoading = true;
        });
        await _extractText(imagePath);
      },
    );
  }

  void _pickImageForPrescription() {
    _showImageSourceDialog(
      onImagePicked: (imagePath) async {
        setState(() {
          _pickedImagePath = imagePath;
          _isLoading = true;
        });
        await _extractTextForPrescription(imagePath);
      },
    );
  }

  int _calculateLevenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<List<int>> matrix = List.generate(
      a.length + 1,
          (i) => List<int>.generate(b.length + 1, (j) => 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        int cost = (a[i - 1].toLowerCase() == b[j - 1].toLowerCase()) ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  Future<String> _compressAndConvertToBase64(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final img.Image? image = img.decodeImage(await imageFile.readAsBytes());

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final img.Image resizedImage = img.copyResize(image, width: 800);
      final List<int> compressedImage = img.encodeJpg(resizedImage, quality: 70);
      return base64Encode(compressedImage);
    } catch (e) {
      print('Error compressing image: $e');
      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    }
  }

  Future<List<String>> _sendImageToGeminiAPI(String imagePath) async {
    const String geminiApiKey = "AIzaSyBktPI-UXkVe48F647saaMHuby7WoNjz1I";
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$geminiApiKey');

    final String base64Image = await _compressAndConvertToBase64(imagePath);

    const prompt = """
You are a medical assistant AI specialized in recognizing medicine names from prescription images. I have an image of a prescription. Your task is to analyze the image and extract only the names of the medicines from the prescription. Be very precise and careful with spelling, as medicine names must be accurate for database matching. Return the medicine names as a list, with each name properly formatted (e.g., capitalize the first letter of each word). If no medicines are found, return an empty list.

Here are some examples of common medicine names to help you recognize them accurately:
- Input: "Take Paracetamol 500mg twice daily, Ibuprofen as needed"
- Output: ["Paracetamol", "Ibuprofen"]
- Input: "Amoxicillin 250mg, Metformin 500mg"
- Output: ["Amoxicillin", "Metformin"]
- Input: "Aspirin 81mg daily, Losartan 50mg"
- Output: ["Aspirin", "Losartan"]

Pay attention to common misspellings and correct them:
- "Paracetmol" should be "Paracetamol"
- "Ibuprfen" should be "Ibuprofen"
- "Amoxicilin" should be "Amoxicillin"

Now, analyze the image and return the list of medicine names with accurate spelling.
""";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        List<String> medicineNames = [];
        try {
          aiResponse = aiResponse.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
          medicineNames = aiResponse.split(',').map((name) => name.trim()).where((name) => name.isNotEmpty).toList();
          medicineNames = medicineNames.map((name) {
            return name.split(' ').map((word) {
              if (word.isNotEmpty) {
                return word[0].toUpperCase() + word.substring(1).toLowerCase();
              }
              return word;
            }).join(' ');
          }).toList();
        } catch (e) {
          print('Error parsing Gemini response: $e');
        }
        return medicineNames;
      } else {
        throw Exception('Failed to get Gemini API response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
      return [];
    }
  }

  Future<void> _extractTextForPrescription(String imagePath) async {
    try {
      List<String> medicineNames = await _sendImageToGeminiAPI(imagePath);
      await _checkMultipleWordsInDatabase(medicineNames);
    } catch (e) {
      print('Error in _extractTextForPrescription: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process the prescription image')),
        );
      }
    }
  }

  Future<void> _extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String extractedText = recognizedText.text;
      List<String> words = extractedText.split(RegExp(r'\s+')).map((word) {
        if (word.isNotEmpty) {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }
        return word;
      }).toList();

      await _checkWordsInDatabase(words);
    } finally {
      await textRecognizer.close();
    }
  }

  Future<void> _checkWordsInDatabase(List<String> words) async {
    bool found = false;
    Map<String, dynamic>? medicine;
    for (String word in words) {
      medicine = await _dbHelper.getMedicineByName(word);
      if (medicine != null) {
        found = true;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedMedicine = medicine;
      });
      _showResultDialog(found);
    }
  }

  Future<void> _checkMultipleWordsInDatabase(List<String> words) async {
    print('Medicine names from Gemini API: $words');

    List<Map<String, dynamic>> foundMedicines = [];
    List<String> notFoundMedicines = [];
    const int maxDistance = 2;

    List<Map<String, dynamic>> allMedicines = await _dbHelper.getAllMedicines();

    for (String word in words) {
      if (word.isEmpty) continue;

      Map<String, dynamic>? medicine = await _dbHelper.getMedicineByName(word);
      if (medicine != null) {
        foundMedicines.add(medicine);
        continue;
      }

      Map<String, dynamic>? closestMatch;
      int minDistance = maxDistance + 1;

      for (var dbMedicine in allMedicines) {
        int distance = _calculateLevenshteinDistance(word.toLowerCase(), dbMedicine['name'].toLowerCase());
        if (distance <= maxDistance && distance < minDistance) {
          minDistance = distance;
          closestMatch = dbMedicine;
        }
      }

      if (closestMatch != null) {
        foundMedicines.add(closestMatch);
        print('Fuzzy match: "$word" matched with "${closestMatch['name']}" (distance: $minDistance)');
      } else {
        notFoundMedicines.add(word);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _showPrescriptionResultsDialog(foundMedicines, notFoundMedicines);
    }
  }

  void _showResultDialog(bool found) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double dialogWidth = constraints.maxWidth * 0.85;
                double dialogHeight = constraints.maxHeight * 0.7;
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20 * constraints.maxWidth / 360)),
                  backgroundColor: Colors.white,
                  contentPadding: EdgeInsets.all(16 * constraints.maxWidth / 360),
                  content: SizedBox(
                    width: dialogWidth,
                    height: dialogHeight,
                    child: found && _selectedMedicine != null
                        ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Medicine Details',
                            style: TextStyle(
                              fontSize: 20 * constraints.maxWidth / 360,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 16 * constraints.maxHeight / 640),
                          if (_pickedImagePath != null)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12 * constraints.maxWidth / 360),
                                child: Image.file(
                                  File(_pickedImagePath!),
                                  width: dialogWidth * 0.5,
                                  height: dialogWidth * 0.5,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: dialogWidth * 0.5,
                                      height: dialogWidth * 0.5,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(12 * constraints.maxWidth / 360),
                                      ),
                                      child: Icon(
                                        Icons.medical_services,
                                        size: 40 * constraints.maxWidth / 360,
                                        color: Colors.blue,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                          else
                            Center(
                              child: Container(
                                width: dialogWidth * 0.5,
                                height: dialogWidth * 0.5,
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12 * constraints.maxWidth / 360),
                                ),
                                child: Icon(
                                  Icons.medical_services,
                                  size: 40 * constraints.maxWidth / 360,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          SizedBox(height: 16 * constraints.maxHeight / 640),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12 * constraints.maxWidth / 360),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12 * constraints.maxWidth / 360),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: dialogWidth * 0.25,
                                    height: dialogWidth * 0.25,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10 * constraints.maxWidth / 360),
                                    ),
                                    child: _selectedMedicine!['imagePath'] != null
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10 * constraints.maxWidth / 360),
                                      child: Image.asset(
                                        _selectedMedicine!['imagePath'],
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.medical_services,
                                            size: 40 * constraints.maxWidth / 360,
                                            color: Colors.blue,
                                          );
                                        },
                                      ),
                                    )
                                        : Icon(
                                      Icons.medical_services,
                                      size: 40 * constraints.maxWidth / 360,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(width: 12 * constraints.maxWidth / 360),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Name: ${_selectedMedicine!['name']}',
                                          style: TextStyle(
                                            fontSize: 16 * constraints.maxWidth / 360,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 8 * constraints.maxHeight / 640),
                                        Text(
                                          'Category: ${_selectedMedicine!['category']}',
                                          style: TextStyle(
                                            fontSize: 14 * constraints.maxWidth / 360,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 8 * constraints.maxHeight / 640),
                                        Text(
                                          'Price: \$${_selectedMedicine!['price']}',
                                          style: TextStyle(
                                            fontSize: 14 * constraints.maxWidth / 360,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No Medicine Found',
                          style: TextStyle(
                            fontSize: 20 * constraints.maxWidth / 360,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 16 * constraints.maxHeight / 640),
                        Text(
                          'The searched medicine was not found in the database.',
                          style: TextStyle(
                            fontSize: 16 * constraints.maxWidth / 360,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    if (found && _selectedMedicine != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _addedProducts[_selectedMedicine!['name']] = 1;
                          });
                          Navigator.pop(context);
                          setState(() {
                            _pickedImagePath = null;
                            _selectedMedicine = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${_selectedMedicine!['name']} added to cart!',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Add to Cart',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16 * constraints.maxWidth / 360,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _pickedImagePath = null;
                          _selectedMedicine = null;
                        });
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16 * constraints.maxWidth / 360,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showPrescriptionResultsDialog(
      List<Map<String, dynamic>> foundMedicines, List<String> notFoundMedicines) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double dialogWidth = constraints.maxWidth * 0.85;
                double dialogHeight = constraints.maxHeight * 0.7;
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20 * constraints.maxWidth / 360)),
                  backgroundColor: Colors.white,
                  contentPadding: EdgeInsets.all(16 * constraints.maxWidth / 360),
                  content: SizedBox(
                    width: dialogWidth,
                    height: dialogHeight,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Prescription Results',
                            style: TextStyle(
                              fontSize: 20 * constraints.maxWidth / 360,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 16 * constraints.maxHeight / 640),
                          if (_pickedImagePath != null)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12 * constraints.maxWidth / 360),
                                child: Image.file(
                                  File(_pickedImagePath!),
                                  width: dialogWidth * 0.6,
                                  height: dialogWidth * 0.6,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: dialogWidth * 0.6,
                                      height: dialogWidth * 0.6,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(12 * constraints.maxWidth / 360),
                                      ),
                                      child: Icon(
                                        Icons.medical_services,
                                        size: 40 * constraints.maxWidth / 360,
                                        color: Colors.blue,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          SizedBox(height: 16 * constraints.maxHeight / 640),
                          if (foundMedicines.isNotEmpty) ...[
                            Text(
                              'Found Medicines:',
                              style: TextStyle(
                                fontSize: 16 * constraints.maxWidth / 360,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8 * constraints.maxHeight / 640),
                            ...foundMedicines.map((medicine) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 8 * constraints.maxHeight / 640),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12 * constraints.maxWidth / 360),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(12 * constraints.maxWidth / 360),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: dialogWidth * 0.25,
                                          height: dialogWidth * 0.25,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10 * constraints.maxWidth / 360),
                                          ),
                                          child: medicine['imagePath'] != null
                                              ? ClipRRect(
                                            borderRadius: BorderRadius.circular(10 * constraints.maxWidth / 360),
                                            child: Image.asset(
                                              medicine['imagePath'],
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.medical_services,
                                                  size: 40 * constraints.maxWidth / 360,
                                                  color: Colors.blue,
                                                );
                                              },
                                            ),
                                          )
                                              : Icon(
                                            Icons.medical_services,
                                            size: 40 * constraints.maxWidth / 360,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        SizedBox(width: 12 * constraints.maxWidth / 360),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Name: ${medicine['name']}',
                                                style: TextStyle(
                                                  fontSize: 14 * constraints.maxWidth / 360,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4 * constraints.maxHeight / 640),
                                              Text(
                                                'Category: ${medicine['category']}',
                                                style: TextStyle(
                                                  fontSize: 12 * constraints.maxWidth / 360,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4 * constraints.maxHeight / 640),
                                              Text(
                                                'Price: \$${medicine['price']}',
                                                style: TextStyle(
                                                  fontSize: 12 * constraints.maxWidth / 360,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8 * constraints.maxWidth / 360),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _addedProducts[medicine['name']] = 1;
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${medicine['name']} added to cart!',
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8 * constraints.maxWidth / 360),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12 * constraints.maxWidth / 360,
                                              vertical: 8 * constraints.maxHeight / 640,
                                            ),
                                          ),
                                          child: Text(
                                            'Add to Cart',
                                            style: TextStyle(fontSize: 12 * constraints.maxWidth / 360),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                          if (notFoundMedicines.isNotEmpty) ...[
                            SizedBox(height: 16 * constraints.maxHeight / 640),
                            Text(
                              'Not Found Medicines:',
                              style: TextStyle(
                                fontSize: 16 * constraints.maxWidth / 360,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8 * constraints.maxHeight / 640),
                            ...notFoundMedicines.map((medicineName) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 4 * constraints.maxHeight / 640),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        medicineName,
                                        style: TextStyle(fontSize: 14 * constraints.maxWidth / 360),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'غير متوفرة، ستتوفر قريبًا',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12 * constraints.maxWidth / 360,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          if (foundMedicines.isEmpty && notFoundMedicines.isEmpty)
                            Text(
                              'No medicines detected in the prescription.',
                              style: TextStyle(fontSize: 16 * constraints.maxWidth / 360, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _pickedImagePath = null;
                        });
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16 * constraints.maxWidth / 360,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _onSearchTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final query = _searchController.text.trim();

      if (query.isEmpty) {
        _removeOverlay();
        setState(() {
          _searchResults = [];
        });
        return;
      }

      final results = await _dbHelper.searchMedicines(query);
      final uniqueResults = <String, Map<String, dynamic>>{};
      for (var result in results) {
        uniqueResults[result['name']] = result;
      }
      final filteredResults = uniqueResults.values.toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
        });
        _showOverlay(context);
      }
    });
  }

  void _showOverlay(BuildContext context) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.2,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            color: Colors.grey[200],
            child: _searchResults.isEmpty
                ? Center(child: Text('No results found', style: TextStyle(fontSize: 16 * MediaQuery.of(context).size.width / 360)))
                : ListView.builder(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final medicine = _searchResults[index];
                return _buildSearchResultItem(medicine);
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSearchResultItem(Map<String, dynamic> medicine) {
    final String medicineName = medicine['name'];
    final bool isAdded = _addedProducts.containsKey(medicineName);
    final int count = _addedProducts[medicineName] ?? 0;

    return Card(
      margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.01),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * MediaQuery.of(context).size.width / 360)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.15,
              height: MediaQuery.of(context).size.width * 0.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10 * MediaQuery.of(context).size.width / 360),
              ),
              child: medicine['imagePath'] != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10 * MediaQuery.of(context).size.width / 360),
                child: Image.asset(
                  medicine['imagePath'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.medical_services,
                      size: MediaQuery.of(context).size.width * 0.075,
                      color: Colors.blue,
                    );
                  },
                ),
              )
                  : Icon(
                Icons.medical_services,
                size: MediaQuery.of(context).size.width * 0.075,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.025),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    medicineName,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Text(
                    'Box • Limited Stock',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Text(
                    'PRICE: ${medicine['price']}',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.025),
            isAdded
                ? Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove,
                    size: MediaQuery.of(context).size.width * 0.045,
                  ),
                  onPressed: () {
                    setState(() {
                      if (count > 1) {
                        _addedProducts[medicineName] = count - 1;
                      } else {
                        _addedProducts.remove(medicineName);
                      }
                      if (_overlayEntry != null) _removeOverlay();
                    });
                  },
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    size: MediaQuery.of(context).size.width * 0.045,
                  ),
                  onPressed: () {
                    setState(() {
                      _addedProducts[medicineName] = count + 1;
                      if (_overlayEntry != null) _removeOverlay();
                    });
                  },
                ),
              ],
            )
                : ElevatedButton(
              onPressed: () {
                setState(() {
                  _addedProducts[medicineName] = 1;
                  if (_overlayEntry != null) _removeOverlay();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * MediaQuery.of(context).size.width / 360),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.03,
                  vertical: MediaQuery.of(context).size.height * 0.015,
                ),
              ),
              child: Text(
                'Add to Cart',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineItem(Map<String, dynamic> medicine) {
    final String medicineName = medicine['name'];
    final bool isAdded = _addedProducts.containsKey(medicineName);
    final int count = _addedProducts[medicineName] ?? 0;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.025,
        vertical: MediaQuery.of(context).size.height * 0.005,
      ),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * MediaQuery.of(context).size.width / 360)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.1,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10 * MediaQuery.of(context).size.width / 360),
              ),
              child: medicine['imagePath'] != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10 * MediaQuery.of(context).size.width / 360),
                child: Image.asset(
                  medicine['imagePath'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.medical_services,
                      size: MediaQuery.of(context).size.width * 0.1,
                      color: Colors.blue,
                    );
                  },
                ),
              )
                  : Icon(
                Icons.medical_services,
                size: MediaQuery.of(context).size.width * 0.1,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              medicineName,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.005),
            Text(
              'Box • Limited Stock',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.032,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.005),
            Text(
              'PRICE: ${medicine['price']}',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            isAdded
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove,
                    size: MediaQuery.of(context).size.width * 0.045,
                  ),
                  onPressed: () {
                    setState(() {
                      if (count > 1) {
                        _addedProducts[medicineName] = count - 1;
                      } else {
                        _addedProducts.remove(medicineName);
                      }
                    });
                  },
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    size: MediaQuery.of(context).size.width * 0.045,
                  ),
                  onPressed: () {
                    setState(() {
                      _addedProducts[medicineName] = count + 1;
                    });
                  },
                ),
              ],
            )
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _addedProducts[medicineName] = 1;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10 * MediaQuery.of(context).size.width / 360),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.015,
                  ),
                ),
                child: Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBar() {
    if (_addedProducts.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'There is a product added',
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.04,
              ),
            ),
            Row(
              children: [
                Text(
                  'Items: ${_addedProducts.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.025),
                ElevatedButton(
                  onPressed: () async {
                    final updatedProducts = await Navigator.push<Map<String, int>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartPage(
                          email: widget.email,
                          addedProducts: Map.from(_addedProducts),
                          selectedAddress: _selectedAddress,
                          onUpdateProducts: (updatedProducts) {
                            setState(() {
                              _addedProducts = updatedProducts;
                            });
                          },
                        ),
                      ),
                    );
                    if (updatedProducts != null) {
                      setState(() {
                        _addedProducts = updatedProducts;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * MediaQuery.of(context).size.width / 360),
                    ),
                  ),
                  child: Text(
                    'View Cart',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startAutoSwitch() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      if (_currentPageAds < _adImages.length - 1) {
        _currentPageAds++;
      } else {
        _currentPageAds = 0;
      }
      _pageController.animateToPage(
        _currentPageAds,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: screenHeight * 0.08),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  color: Colors.blue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Deliver to',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.055,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                GestureDetector(
                                  onTap: _showAddressPicker,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: screenWidth * 0.6,
                                    ),
                                    child: Text(
                                      _shortenAddress(_selectedAddress),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: screenWidth * 0.02),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(widget.email)
                                  .collection('userOrders')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return IconButton(
                                    icon: Icon(Icons.track_changes, color: Colors.white, size: screenWidth * 0.075),
                                    tooltip: 'Track Orders',
                                    onPressed: null,
                                  );
                                }
                                if (snapshot.hasError) {
                                  print('Error fetching orders: ${snapshot.error}');
                                  return IconButton(
                                    icon: Icon(Icons.track_changes, color: Colors.white, size: screenWidth * 0.075),
                                    tooltip: 'Track Orders',
                                    onPressed: null,
                                  );
                                }
                                final orderCount = snapshot.data?.docs.length ?? 0;
                                return IconButton(
                                  icon: Stack(
                                    children: [
                                      Icon(Icons.track_changes, color: Colors.white, size: screenWidth * 0.075),
                                      if (orderCount > 0)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(2 * screenWidth / 360),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: BoxConstraints(
                                              minWidth: 16 * screenWidth / 360,
                                              minHeight: 16 * screenWidth / 360,
                                            ),
                                            child: Text(
                                              '$orderCount',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10 * screenWidth / 360,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  tooltip: 'Track Orders',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderTrackingPage(
                                          email: widget.email,
                                          onOrderCountChanged: (count) {},
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8 * screenWidth / 360),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'What are you looking for?',
                            hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, size: screenWidth * 0.045),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildButton(
                            'Prescription or Claim',
                            Icons.local_pharmacy,
                            screenHeight * 0.08,
                            onTap: _pickImageForPrescription,
                          ),
                          _buildButton(
                            'Product Picture',
                            Icons.camera_alt,
                            screenHeight * 0.08,
                            onTap: _pickImage,
                          ),
                          _buildButton(
                            'Pharmacist Assistance',
                            Icons.phone,
                            screenHeight * 0.08,
                            onTap: _makePhoneCall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015,
                    horizontal: screenWidth * 0.05,
                  ),
                  child: SizedBox(
                    height: screenHeight * 0.2,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _adImages.length,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPageAds = page;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.0125),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8 * screenWidth / 360),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8 * screenWidth / 360),
                            child: Image.asset(
                              _adImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(Icons.error, color: Colors.red, size: screenWidth * 0.075),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_isLoading)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
                    child: Lottie.asset(
                      'assets/animation/loader.json',
                      height: screenHeight * 0.15,
                      width: screenWidth * 0.25,
                    ),
                  ),
                if (_isContentLoading)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
                    child: Lottie.asset(
                      'assets/animation/loader.json',
                      height: screenHeight * 0.15,
                      width: screenWidth * 0.25,
                    ),
                  )
                else if (_displayedMedicines.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Text(
                      'No medicines available',
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                  )
                else
                  Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.025,
                          vertical: screenHeight * 0.015,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth > 600 ? 3 : 2,
                          crossAxisSpacing: screenWidth * 0.030,
                          mainAxisSpacing: screenHeight * 0.015,
                          childAspectRatio: screenWidth > 600 ? 0.8 : 0.75,
                        ),
                        itemCount: _displayedMedicines.length,
                        itemBuilder: (context, index) {
                          final medicine = _displayedMedicines[index];
                          return _buildMedicineItem(medicine);
                        },
                      ),
                      if (_displayedMedicines.length < _allMedicines.length)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
                          child: ElevatedButton(
                            onPressed: _loadMoreMedicines,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8 * screenWidth / 360)),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                                vertical: screenHeight * 0.015,
                              ),
                            ),
                            child: Text(
                              'Load More',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: screenHeight * 0.1),
                    ],
                  ),
              ],
            ),
          ),
          _buildCartBar(),
        ],
      ),
    );
  }

  void _showAddressPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20 * MediaQuery.of(context).size.width / 360)),
              backgroundColor: Colors.white,
              title: Text(
                'Select Delivery Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18 * MediaQuery.of(context).size.width / 360),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_addresses.isEmpty)
                      Text(
                        'No addresses found.',
                        style: TextStyle(fontSize: 16 * MediaQuery.of(context).size.width / 360),
                      )
                    else
                      ..._addresses.map((address) {
                        String fullAddress =
                            '${address['details']}, ${address['city']}, ${address['governorate']}, ${address['country']}';
                        return ListTile(
                          title: Text(
                            fullAddress,
                            style: TextStyle(fontSize: 14 * MediaQuery.of(context).size.width / 360),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedAddress = fullAddress;
                            });
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddressManagementPage(email: widget.email),
                          ),
                        );
                        if (result == true) {
                          await _fetchAddressesFromFirebase();
                          if (_addresses.isNotEmpty) {
                            String newAddress =
                                '${_addresses.last['details']}, ${_addresses.last['city']}, ${_addresses.last['governorate']}, ${_addresses.last['country']}';
                            setState(() {
                              _selectedAddress = newAddress;
                            });
                          }
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8 * MediaQuery.of(context).size.width / 360)),
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                          vertical: MediaQuery.of(context).size.height * 0.015,
                        ),
                      ),
                      child: Text(
                        'Add New Address',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16 * MediaQuery.of(context).size.width / 360,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(String label, IconData icon, double buttonHeight, {VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.01),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: Size(0, buttonHeight),
            padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.015),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8 * MediaQuery.of(context).size.width / 360)),
            side: const BorderSide(color: Colors.blue),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue, size: MediaQuery.of(context).size.width * 0.07),
              SizedBox(height: MediaQuery.of(context).size.height * 0.007),
              Text(
                label,
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: MediaQuery.of(context).size.width * 0.03,
                ),
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _removeOverlay();
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}