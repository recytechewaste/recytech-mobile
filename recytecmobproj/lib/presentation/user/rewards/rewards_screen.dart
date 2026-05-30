import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rewards & Points'),
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          children: [
            Text(
              'Your Impact Rewards',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Earn points every time you recycle your e‑waste with RecyTech.',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 18.h),

            // Total points card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.06),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54.w,
                    height: 54.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: const Color(0xFF1B5E20),
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Points',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '320 pts',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'You are close to your next reward.\nKeep recycling to unlock more perks.',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 22.h),
            Text(
              'Recent reward transactions',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10.h),

            _historyRow(
              title: 'Pickup REQ-12345 • Old Laptop',
              date: 'Collected on May 14, 2025',
              points: '+80 pts',
            ),
            const Divider(color: Colors.black12),
            _historyRow(
              title: 'Pickup REQ-12098 • Desktop Computer',
              date: 'Collected on September 25, 2025',
              points: '+60 pts',
            ),
            const Divider(color: Colors.black12),
            _historyRow(
              title: 'Pickup REQ-11672 • Tablet',
              date: 'Collected on June 20, 2025',
              points: '+40 pts',
            ),
            const Divider(color: Colors.black12),
            _historyRow(
              title: 'Pickup REQ-11002 • Chargers & Cables',
              date: 'Collected on April 10, 2025',
              points: '+30 pts',
            ),

            SizedBox(height: 24.h),
            Text(
              'How to earn more',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10.h),
            _bullet(
              'Submit more e‑waste through pickup requests or drop‑off partners.',
            ),
            _bullet(
              'Sort and categorize items correctly to help our AI model.',
            ),
            _bullet(
              'Invite friends and family to recycle their old devices (coming soon).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyRow({
    required String title,
    required String date,
    required String points,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            points,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: 11.sp),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

