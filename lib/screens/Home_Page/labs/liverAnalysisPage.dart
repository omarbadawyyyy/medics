
// صفحة تحليل الكبد
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LiverAnalysisPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liver Analysis'),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: Text('هذه صفحة تحليل الكبد. يمكنك إضافة تفاصيل التحليل هنا.'),
      ),
    );
  }
}

