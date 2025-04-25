import 'package:flutter/material.dart';

class BMICalculatorPage extends StatefulWidget {
  @override
  _BMICalculatorPageState createState() => _BMICalculatorPageState();
}

class _BMICalculatorPageState extends State<BMICalculatorPage> {
  String _gender = 'Male'; // الجنس المحدد
  double _height = 165; // الطول (بالسنتيمتر)
  double _weight = 57; // الوزن (بالكيلوجرام)
  int _age = 22; // العمر
  double _bmi = 0; // نتيجة حساب BMI
  bool _showResult = false; // لعرض نتيجة BMI

  void _calculateBMI() {
    setState(() {
      // حساب BMI باستخدام الصيغة: الوزن (كجم) / (الطول (متر) * الطول (متر))
      double heightInMeters = _height / 100;
      _bmi = _weight / (heightInMeters * heightInMeters);
      _showResult = true; // عرض النتيجة
    });
  }

  void _updateHeight(double value) {
    setState(() {
      _height = value;
    });
  }

  void _updateWeight(double value) {
    setState(() {
      _weight = value;
    });
  }

  void _updateAge(double value) {
    setState(() {
      _age = value.toInt();
    });
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return 'Normal';
    } else if (bmi >= 25 && bmi <= 29.9) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BMI Calculator'),
      ),
      body: Stack(
        children: [
          // الصفحة الرئيسية
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // اختيار الجنس
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderButton('Male', Icons.male),
                    ),
                    SizedBox(width: 16), // مسافة بين العنصرين
                    Expanded(
                      child: _buildGenderButton('Female', Icons.female),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // إدخال الطول
                Text(
                  'Height (in cm)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_left),
                      onPressed: () {
                        _updateHeight(_height - 1); // تقليل الطول بمقدار 1
                      },
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: Text(
                        '${_height.toStringAsFixed(0)} cm',
                        key: ValueKey(_height), // لتحديث الانيميشن عند تغيير القيمة
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_right),
                      onPressed: () {
                        _updateHeight(_height + 1); // زيادة الطول بمقدار 1
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // تصميم غير تقليدي للـ Slider (الطول)
                _buildCustomSlider(_height, 100, 250, _updateHeight),
                SizedBox(height: 20),
                // إدخال الوزن
                Text(
                  'Weight (in kg)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_left),
                      onPressed: () {
                        _updateWeight(_weight - 1); // تقليل الوزن بمقدار 1
                      },
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: Text(
                        '${_weight.toStringAsFixed(0)} kg',
                        key: ValueKey(_weight), // لتحديث الانيميشن عند تغيير القيمة
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_right),
                      onPressed: () {
                        _updateWeight(_weight + 1); // زيادة الوزن بمقدار 1
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // تصميم غير تقليدي للـ Slider (الوزن)
                _buildCustomSlider(_weight, 30, 200, _updateWeight), // زيادة الحد الأقصى للوزن إلى 200
                SizedBox(height: 20),
                // إدخال العمر
                Text(
                  'Age',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_left),
                      onPressed: () {
                        _updateAge(_age - 1); // تقليل العمر بمقدار 1
                      },
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: Text(
                        '$_age years',
                        key: ValueKey(_age), // لتحديث الانيميشن عند تغيير القيمة
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_right),
                      onPressed: () {
                        _updateAge(_age + 1); // زيادة العمر بمقدار 1
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // تصميم غير تقليدي للـ Slider (العمر)
                _buildCustomSlider(_age.toDouble(), 1, 100, _updateAge),
                SizedBox(height: 20),
                // زر حساب BMI
                ElevatedButton(
                  onPressed: _calculateBMI,
                  child: Text(
                    'Calculate BMI',
                    style: TextStyle(fontSize: 18, color: Colors.white), // لون النص أبيض
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          // نتيجة BMI (تنبثق من الأسفل)
          if (_showResult)
            AnimatedPositioned(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeOut,
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Your BMI is',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '${_bmi.toStringAsFixed(1)} kg/m²',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '(${_getBMICategory(_bmi)})',
                      style: TextStyle(fontSize: 18, color: Colors.blue[900]),
                    ),
                    SizedBox(height: 20),
                    Text(
                      _getBMICategory(_bmi) == 'Normal'
                          ? 'A BMI of 18.5-24.9 indicates that you are at a healthy weight for your height. By maintaining a healthy weight, you lower your risk of developing serious health problems.'
                          : 'A BMI outside the normal range may indicate health risks. Consult a healthcare professional for advice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showResult = false; // إخفاء النتيجة
                        });
                      },
                      child: Text(
                        'Close',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // دالة لبناء زر اختيار الجنس
  Widget _buildGenderButton(String gender, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = gender;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(16),
        height: 120, // زيادة ارتفاع الكونتينر
        decoration: BoxDecoration(
          color: _gender == gender ? Colors.blue[900]! : Colors.grey[300]!, // استخدام ! لتأكيد أن القيمة ليست null
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _gender == gender ? Colors.blue[900]! : Colors.grey[300]!, // استخدام ! لتأكيد أن القيمة ليست null
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: _gender == gender ? Colors.white : Colors.black,
            ),
            SizedBox(height: 10),
            Text(
              gender,
              style: TextStyle(
                fontSize: 16,
                color: _gender == gender ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لبناء Slider مخصص
  Widget _buildCustomSlider(double value, double min, double max, Function(double) onChanged) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
          thumbColor: Colors.white,
        ),
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
