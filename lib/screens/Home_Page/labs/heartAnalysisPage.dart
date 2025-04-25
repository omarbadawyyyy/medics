import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class HeartAnalysisPage extends StatefulWidget {
  const HeartAnalysisPage({Key? key}) : super(key: key);

  @override
  _HeartAnalysisPageState createState() => _HeartAnalysisPageState();
}

class _HeartAnalysisPageState extends State<HeartAnalysisPage> {
  tfl.Interpreter? _interpreter;
  String? _predictionResult;

  // وحدات التحكم للحقول النصية
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _trestbpsController = TextEditingController();
  final TextEditingController _cholController = TextEditingController();
  final TextEditingController _thalachController = TextEditingController();
  final TextEditingController _oldpeakController = TextEditingController();

  // القيم المختارة للقوائم المنسدلة
  int? _selectedSex;
  int? _selectedCp;
  int? _selectedFbs;
  int? _selectedRestecg;
  int? _selectedExang;
  int? _selectedSlope;
  int? _selectedCa;
  int? _selectedThal;

  // قيم المتوسط والانحراف المعياري لكل سمة (مستخدمة لتطبيع البيانات)
  final Map<String, Map<String, double>> _scalerParams = {
    'age': {'mean': 54.4, 'std': 9.1},
    'sex': {'mean': 0.68, 'std': 0.47},
    'cp': {'mean': 0.96, 'std': 1.03},
    'trestbps': {'mean': 131.6, 'std': 17.5},
    'chol': {'mean': 246.3, 'std': 51.8},
    'fbs': {'mean': 0.15, 'std': 0.36},
    'restecg': {'mean': 0.53, 'std': 0.53},
    'thalach': {'mean': 149.6, 'std': 22.9},
    'exang': {'mean': 0.33, 'std': 0.47},
    'oldpeak': {'mean': 1.04, 'std': 1.16},
    'slope': {'mean': 1.4, 'std': 0.62},
    'ca': {'mean': 0.73, 'std': 1.02},
    'thal': {'mean': 2.31, 'std': 0.61},
  };

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // تحميل نموذج TFLite
  Future<void> _loadModel() async {
    try {
      _interpreter = await tfl.Interpreter.fromAsset('assets/heart_disease_model.tflite');
      print("Model loaded successfully / تم تحميل النموذج بنجاح");
    } catch (e) {
      print("Error loading model: $e / خطأ أثناء تحميل النموذج: $e");
      setState(() {
        _predictionResult = "Failed to load model / فشل تحميل النموذج";
      });
    }
  }

  // دالة لتطبيع القيم
  double _standardize(double value, double mean, double std) {
    return (value - mean) / std;
  }

  // دالة التنبؤ بأمراض القلب
  Future<void> _predictHeartDisease() async {
    if (_interpreter == null) {
      setState(() {
        _predictionResult = "Model not loaded / لم يتم تحميل النموذج";
      });
      return;
    }

    // التحقق من أن جميع الحقول مملوءة
    if (_ageController.text.isEmpty ||
        _trestbpsController.text.isEmpty ||
        _cholController.text.isEmpty ||
        _thalachController.text.isEmpty ||
        _oldpeakController.text.isEmpty ||
        _selectedSex == null ||
        _selectedCp == null ||
        _selectedFbs == null ||
        _selectedRestecg == null ||
        _selectedExang == null ||
        _selectedSlope == null ||
        _selectedCa == null ||
        _selectedThal == null) {
      setState(() {
        _predictionResult = "Please fill all fields / يرجى ملء جميع الحقول";
      });
      return;
    }

    try {
      // جمع البيانات من الحقول النصية
      double age = double.parse(_ageController.text);
      double trestbps = double.parse(_trestbpsController.text);
      double chol = double.parse(_cholController.text);
      double thalach = double.parse(_thalachController.text);
      double oldpeak = double.parse(_oldpeakController.text);

      // جمع البيانات من القوائم المنسدلة
      double sex = _selectedSex!.toDouble();
      double cp = _selectedCp!.toDouble();
      double fbs = _selectedFbs!.toDouble();
      double restecg = _selectedRestecg!.toDouble();
      double exang = _selectedExang!.toDouble();
      double slope = _selectedSlope!.toDouble();
      double ca = _selectedCa!.toDouble();
      double thal = _selectedThal!.toDouble();

      // تطبيع البيانات
      double scaledAge = _standardize(age, _scalerParams['age']!['mean']!, _scalerParams['age']!['std']!);
      double scaledSex = _standardize(sex, _scalerParams['sex']!['mean']!, _scalerParams['sex']!['std']!);
      double scaledCp = _standardize(cp, _scalerParams['cp']!['mean']!, _scalerParams['cp']!['std']!);
      double scaledTrestbps = _standardize(trestbps, _scalerParams['trestbps']!['mean']!, _scalerParams['trestbps']!['std']!);
      double scaledChol = _standardize(chol, _scalerParams['chol']!['mean']!, _scalerParams['chol']!['std']!);
      double scaledFbs = _standardize(fbs, _scalerParams['fbs']!['mean']!, _scalerParams['fbs']!['std']!);
      double scaledRestecg = _standardize(restecg, _scalerParams['restecg']!['mean']!, _scalerParams['restecg']!['std']!);
      double scaledThalach = _standardize(thalach, _scalerParams['thalach']!['mean']!, _scalerParams['thalach']!['std']!);
      double scaledExang = _standardize(exang, _scalerParams['exang']!['mean']!, _scalerParams['exang']!['std']!);
      double scaledOldpeak = _standardize(oldpeak, _scalerParams['oldpeak']!['mean']!, _scalerParams['oldpeak']!['std']!);
      double scaledSlope = _standardize(slope, _scalerParams['slope']!['mean']!, _scalerParams['slope']!['std']!);
      double scaledCa = _standardize(ca, _scalerParams['ca']!['mean']!, _scalerParams['ca']!['std']!);
      double scaledThal = _standardize(thal, _scalerParams['thal']!['mean']!, _scalerParams['thal']!['std']!);

      // تحضير المدخلات للنموذج (13 سمة)
      var input = [
        [
          scaledAge,
          scaledSex,
          scaledCp,
          scaledTrestbps,
          scaledChol,
          scaledFbs,
          scaledRestecg,
          scaledThalach,
          scaledExang,
          scaledOldpeak,
          scaledSlope,
          scaledCa,
          scaledThal,
        ]
      ];

      // تحضير المخرجات (افتراض: احتمالية واحدة)
      var output = List<double>.filled(1, 0).reshape([1, 1]);

      // تشغيل النموذج
      _interpreter!.run(input, output);

      // معالجة النتيجة
      double prediction = output[0][0];
      setState(() {
        _predictionResult = prediction > 0.5
            ? "Positive for Heart Disease (Risk Detected) / إيجابي لأمراض القلب (تم اكتشاف مخاطر)"
            : "Negative for Heart Disease (Low Risk) / سلبي لأمراض القلب (مخاطر منخفضة)";
      });
    } catch (e) {
      setState(() {
        _predictionResult = "Error: Please enter valid numbers ($e) / خطأ: من فضلك أدخل أرقامًا صحيحة ($e)";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Heart Analysis / تحليل القلب',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey[200],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الصفحة
              const Text(
                'Enter your data for Heart Disease Analysis / أدخل بياناتك لتحليل مخاطر أمراض القلب',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // حقل العمر
              const Text(
                'Age / العمر',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildTextField(_ageController, 'Example: 45 / مثال: 45'),
              const SizedBox(height: 10),

              // حقل الجنس
              const Text(
                'Sex / الجنس',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildDropdownField(
                [
                  DropdownMenuItem(value: 1, child: Text('Male / ذكر')),
                  DropdownMenuItem(value: 0, child: Text('Female / أنثى')),
                ],
                _selectedSex,
                    (value) => setState(() => _selectedSex = value),
              ),
              const SizedBox(height: 10),

              // حقل نوع ألم الصدر
              const Text(
                'Chest Pain Type / نوع ألم الصدر',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildDropdownField(
                [
                  DropdownMenuItem(value: 0, child: Text('0: No Pain / 0: لا ألم')),
                  DropdownMenuItem(value: 1, child: Text('1: Atypical Angina / 1: ألم غير نمطي')),
                  DropdownMenuItem(value: 2, child: Text('2: Typical Angina / 2: ألم نمطي')),
                  DropdownMenuItem(value: 3, child: Text('3: Non-Anginal Pain / 3: ألم غير ذبحي')),
                ],
                _selectedCp,
                    (value) => setState(() => _selectedCp = value),
              ),
              const SizedBox(height: 10),

              // حقل ضغط الدم
              const Text(
                'Resting Blood Pressure (mmHg) / ضغط الدم عند الراحة (ملم زئبق)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildTextField(_trestbpsController, 'Example: 120 / مثال: 120'),
              const SizedBox(height: 10),

              // حقل الكوليسترول
              const Text(
                'Cholesterol (mg/dL) / الكوليسترول (ملغ/ديسيلتر)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildTextField(_cholController, 'Example: 200 / مثال: 200'),
              const SizedBox(height: 10),

              // حقل سكر الدم
              const Text(
                'Fasting Blood Sugar > 120 mg/dL / سكر الدم الصائم > 120 ملغ/ديسيلتر',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildDropdownField(
                [
                  DropdownMenuItem(value: 1, child: Text('Yes / صحيح')),
                  DropdownMenuItem(value: 0, child: Text('No / خاطئ')),
                ],
                _selectedFbs,
                    (value) => setState(() => _selectedFbs = value),
              ),
              const SizedBox(height: 10),

              // حقل نتائج تخطيط القلب
              const Text(
                'Resting ECG Results / نتائج تخطيط القلب عند الراحة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildDropdownField(
                [
                  DropdownMenuItem(value: 0, child: Text('0: Normal / 0: طبيعي')),
                  DropdownMenuItem(value: 1, child: Text('1: ST-T Abnormality / 1: شذوذ في موجة ST-T')),
                  DropdownMenuItem(value: 2, child: Text('2: Left Ventricular Hypertrophy / 2: تضخم البطين الأيسر')),
                ],
                _selectedRestecg,
                    (value) => setState(() => _selectedRestecg = value),
              ),
              const SizedBox(height: 10),

              // حقل أقصى معدل نبضات القلب
              const Text(
                'Maximum Heart Rate / أقصى معدل نبضات القلب',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildTextField(_thalachController, 'Example: 150 / مثال: 150'),
              const SizedBox(height: 10),

              // حقل الذبحة الناتجة عن التمارين
              const Text(
                'Exercise Induced Angina / الذبحة الناتجة عن التمارين',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildDropdownField(
                [
                  DropdownMenuItem(value: 1, child: Text('Yes / نعم')),
                  DropdownMenuItem(value: 0, child: Text('No / لا')),
                ],
                _selectedExang,
                    (value) => setState(() => _selectedExang = value),
              ),
              const SizedBox(height: 10),

              // حقل انخفاض ST
              const Text(
                'ST Depression (Oldpeak) / انخفاض ST (Oldpeak)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildTextField(_oldpeakController, 'Example: 1.0 / مثال: 1.0'),
              const SizedBox(height: 10),

              // حقل انحدار ST
              const Text(
                'Slope of ST Segment / انحدار قمة ST أثناء التمارين',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildDropdownField(
                [
                  DropdownMenuItem(value: 0, child: Text('0: Upsloping / 0: تصاعدي')),
                  DropdownMenuItem(value: 1, child: Text('1: Flat / 1: مسطح')),
                  DropdownMenuItem(value: 2, child: Text('2: Downsloping / 2: تنازلي')),
                ],
                _selectedSlope,
                    (value) => setState(() => _selectedSlope = value),
              ),
              const SizedBox(height: 10),

              // حقل عدد الأوعية
              const Text(
                'Number of Major Vessels / عدد الأوعية الرئيسية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildDropdownField(
                [
                  DropdownMenuItem(value: 0, child: Text('0')),
                  DropdownMenuItem(value: 1, child: Text('1')),
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                ],
                _selectedCa,
                    (value) => setState(() => _selectedCa = value),
              ),
              const SizedBox(height: 10),

              // حقل الثالاسيميا
              const Text(
                'Thalassemia / الثالاسيميا',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildDropdownField(
                [
                  DropdownMenuItem(value: 1, child: Text('1: Normal / 1: طبيعي')),
                  DropdownMenuItem(value: 2, child: Text('2: Fixed Defect / 2: عيب ثابت')),
                  DropdownMenuItem(value: 3, child: Text('3: Reversible Defect / 3: عيب عكسي')),
                ],
                _selectedThal,
                    (value) => setState(() => _selectedThal = value),
              ),
              const SizedBox(height: 20),

              // زر التنبؤ
              Center(
                child: ElevatedButton(
                  onPressed: _predictHeartDisease,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Predict / تنبؤ',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // عرض النتيجة
              if (_predictionResult != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    _predictionResult!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء حقول النص
  Widget _buildTextField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء القوائم المنسدلة
  Widget _buildDropdownField(
      List<DropdownMenuItem<int>> items, int? selectedValue, ValueChanged<int?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: DropdownButtonFormField<int>(
          value: selectedValue,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _trestbpsController.dispose();
    _cholController.dispose();
    _thalachController.dispose();
    _oldpeakController.dispose();
    _interpreter?.close();
    super.dispose();
  }
}
