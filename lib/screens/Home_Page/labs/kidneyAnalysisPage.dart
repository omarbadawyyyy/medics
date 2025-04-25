

// صفحة تحليل الكلى
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KidneyAnalysisPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kidney Analysis'),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: Text('هذه صفحة تحليل الكلى. يمكنك إضافة تفاصيل التحليل هنا.'),
      ),
    );
  }
}