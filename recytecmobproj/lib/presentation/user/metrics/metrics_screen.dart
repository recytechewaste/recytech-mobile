import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metrics')),
      body: Center(child: Text('Metrics Page (hard-coded)', style: TextStyle(fontSize: 14.sp))),
    );
  }
}
