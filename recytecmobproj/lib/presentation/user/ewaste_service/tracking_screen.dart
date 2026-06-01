import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For now this is a static example of a request
    const String requestId = 'REQ-12345';
    const String status = 'Accepted'; // Pending | Accepted | Collected

    int statusIndex(String s) {
      switch (s) {
        case 'Pending':
          return 0;
        case 'Accepted':
          return 1;
        case 'Collected':
          return 2;
        default:
          return 0;
      }
    }

    final currentIndex = statusIndex(status);

    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Pickup Tracking'),
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          children: [
            Text(
              'Request ID: $requestId',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: RecyTechTheme.textDark,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Text(
                  'Current status: ',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: RecyTechTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: RecyTechTheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: RecyTechTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Text(
              'Pickup Flow',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: RecyTechTheme.textDark,
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: RecyTechTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: RecyTechTheme.primary.withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _stepTile(
                    index: 0,
                    currentIndex: currentIndex,
                    title: 'Pending',
                    description:
                        'Your pickup request has been submitted and is waiting to be accepted by a collector.',
                  ),
                  _stepTile(
                    index: 1,
                    currentIndex: currentIndex,
                    title: 'Accepted',
                    description:
                        'A collector has accepted your request and is preparing to collect your e-waste.',
                  ),
                  _stepTile(
                    index: 2,
                    currentIndex: currentIndex,
                    title: 'Collected',
                    description:
                        'The collector has successfully picked up your e-waste. Tracking for this request will now end.',
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            const Divider(),
            SizedBox(height: 12.h),
            Text(
              'After the collector confirms successful pickup, this request will move to your Pickup History. '
              'Any eligible monetary payout will be released after drop-off confirmation and shown in your Payout History.',
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textDark,
                height: 1.35,
              ),
            ),
            SizedBox(height: 18.h),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Tracking is only available until the pickup is marked as Collected.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: RecyTechTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _stepTile({
  required int index,
  required int currentIndex,
  required String title,
  required String description,
}) {
  final bool reached = index <= currentIndex;
  final bool isCurrent = index == currentIndex;

  return Padding(
    padding: EdgeInsets.only(bottom: 10.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? RecyTechTheme.primary : RecyTechTheme.border,
          ),
          child: Icon(
            reached ? Icons.check : Icons.circle,
            size: reached ? 14.sp : 10.sp,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: isCurrent
                      ? RecyTechTheme.primary
                      : RecyTechTheme.textDark,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: RecyTechTheme.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
