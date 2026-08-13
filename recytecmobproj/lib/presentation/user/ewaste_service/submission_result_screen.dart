import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:recytecmobproj/widgets/ui_components.dart';

class SubmissionResultScreen extends StatelessWidget {
  const SubmissionResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RESULTS')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Text('RESULTS',
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.w800))),
                SizedBox(height: 12.h),
                Container(
                  height: 120.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black12.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Text('Detected Item:',
                    style: TextStyle(
                        fontSize: 12.sp, fontWeight: FontWeight.w700)),
                Text('Old Laptop', style: TextStyle(fontSize: 12.sp)),
                SizedBox(height: 6.h),
                Text('Category:',
                    style: TextStyle(
                        fontSize: 12.sp, fontWeight: FontWeight.w700)),
                Text('Electronic Devices', style: TextStyle(fontSize: 12.sp)),
                SizedBox(height: 6.h),
                Text('Condition:',
                    style: TextStyle(
                        fontSize: 12.sp, fontWeight: FontWeight.w700)),
                Text('Damaged', style: TextStyle(fontSize: 12.sp)),
                SizedBox(height: 6.h),
                Text('Recommended Action:',
                    style: TextStyle(
                        fontSize: 12.sp, fontWeight: FontWeight.w700)),
                Text('Proceed with certified recycling',
                    style: TextStyle(fontSize: 12.sp)),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          PrimaryButton(
              label: 'Submit E-waste', onPressed: () => Navigator.pop(context)),
          SizedBox(height: 10.h),
          PrimaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context),
              filled: false),
        ],
      ),
    );
  }
}
