import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatWithAIPage extends StatefulWidget {
  @override
  _ChatWithAIPageState createState() => _ChatWithAIPageState();
}

class _ChatWithAIPageState extends State<ChatWithAIPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = [];
  final String _apiKey = 'AIzaSyBktPI-UXkVe48F647saaMHuby7WoNjz1I';
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  String? _userName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserNameAndShowWelcomeMessage();
  }

  void _loadUserNameAndShowWelcomeMessage() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userName = user?.displayName ?? 'مستخدم';
      _messages.add({
        "sender": "AI",
        "content": "مرحبًا $_userName! أنا مساعدك الذكي. كيف يمكنني مساعدتك في استفساراتك الطبية اليوم؟"
      });
    });
  }

  Future<void> _sendMessage(String message, {File? file}) async {
    if (message.isEmpty && file == null) return;

    setState(() {
      _messages.add({"sender": "أنت", "content": message.isNotEmpty ? message : "تم رفع ملف"});
      _isLoading = true;
    });

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey');
      var requestBody = {
        "contents": [
          {
            "parts": <Map<String, dynamic>>[
              {
                "text": message.isNotEmpty
                    ? "هذا استفسار طبي. قم بتحليل النص التالي وقدم تشخيصات أولية باللغة العربية فقط، رتب الرد في قائمة مرقمة واضحة، وفي النهاية قدم تشخيصًا عامًا للحالة: $message"
                    : "هذا ملف طبي. قم بتحليل الملف وقدم تشخيصات أولية باللغة العربية فقط، رتب الرد في قائمة مرقمة واضحة، وفي النهاية قدم تشخيصًا عامًا للحالة."
              }
            ]
          }
        ]
      };

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        requestBody["contents"]?[0]["parts"]?.add({
          "inlineData": {
            "mimeType": _getMimeType(file.path),
            "data": base64String,
          }
        });
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add({"sender": "AI", "content": aiResponse});
        });
      } else {
        setState(() {
          _messages.add({"sender": "AI", "content": "خطأ: تعذر الحصول على رد من Gemini API."});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"sender": "AI", "content": "خطأ: $e"});
      });
    }

    setState(() {
      _isLoading = false;
      _controller.clear();
      _selectedFile = null;
    });
  }

  String _getMimeType(String path) {
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.pdf')) return 'application/pdf';
    if (path.endsWith('.doc') || path.endsWith('.docx')) return 'application/msword';
    return 'application/octet-stream';
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
      await _sendMessage("", file: _selectedFile);
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
      await _sendMessage("", file: _selectedFile);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
      await _sendMessage("", file: _selectedFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الدردشة مع الذكاء الاصطناعي'),
        backgroundColor: Colors.blue[900],
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[50]!],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    padding: EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message["sender"] == "أنت";
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue[600] : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              message['content']!,
                              style: TextStyle(
                                fontSize: 16,
                                color: isUser ? Colors.white : Colors.black87,
                                height: 1.6,
                                fontFamily: 'Arabic',
                              ),
                              textDirection: TextDirection.rtl,
                              softWrap: true,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: (index * 100).ms);
                    },
                  ),
                  if (_isLoading)
                    Positioned(
                      bottom: 10,
                      left: MediaQuery.of(context).size.width / 2 - 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[900]!),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIconButton(Icons.photo, Colors.blue[900]!, _pickImageFromGallery, "معرض الصور"),
                      _buildIconButton(Icons.camera_alt, Colors.blue[900]!, _pickImageFromCamera, "كاميرا"),
                      _buildIconButton(Icons.attach_file, Colors.blue[900]!, _pickFile, "ملف"),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'اكتب رسالتك...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      FloatingActionButton(
                        onPressed: () => _sendMessage(_controller.text),
                        backgroundColor: Colors.blue[900],
                        mini: true,
                        child: Icon(Icons.send, color: Colors.white),
                        elevation: 2,
                      ),
                    ],
                  ),
                  if (_selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "الملف المختار: ${_selectedFile!.path.split('/').last}",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue[50],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: color, size: 28),
          onPressed: onPressed,
        ),
      ),
    );
  }
}