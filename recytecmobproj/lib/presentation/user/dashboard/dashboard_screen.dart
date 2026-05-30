import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../widgets/primary_button.dart';
import '../ewaste_service/ai_capture_screen.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  // RecyTech palette
  static const _primary = Color(0xFF1B5E20); // eco green
  static const _secondary = Color(0xFF00897B); // teal
  static const _accent = Color(0xFFF9A825); // amber
  static const _bg = Color(0xFFF5F7F4);
  static const _textDark = Color(0xFF0F172A);

  Widget _infoCard({
    required String title,
    required String body,
    required IconData icon,
    required Color tint,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: tint, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5.sp,
                    color: _textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.black38, size: 20.sp),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w900,
            color: _textDark,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11.sp, color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('Homepage'),
          centerTitle: true,
          actions: const [
            Icon(Icons.search),
            SizedBox(width: 12),
            Icon(Icons.more_vert),
            SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          children: [
            Text(
              'Hi, Username!',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Manage your e-waste responsibly today',
              style: TextStyle(fontSize: 11.sp, color: Colors.black54),
            ),
            SizedBox(height: 16.h),

            // 🔹 FIRST CONTENT CARDS
            _infoCard(
              title: 'New AI Features',
              body: 'We introduced new AI features to improve user experience.',
              icon: Icons.auto_awesome,
              tint: _secondary,
            ),
            SizedBox(height: 12.h),
            _infoCard(
              title: 'Environmental Impact',
              body: 'Learn how e-waste recycling helps the environment.',
              icon: Icons.public,
              tint: _accent,
            ),

            SizedBox(height: 22.h),

            _sectionTitle(
              'AI-Driven E-Waste Management',
              'Manage your electronic waste effectively with AI technologies.',
            ),
            SizedBox(height: 16.h),

            Center(
              child: PrimaryButton(
                text: 'Learn More',
                filled: false,
                width: 220.w,
                onPressed: () {},
              ),
            ),
            SizedBox(height: 10.h),

            Center(
              child: PrimaryButton(
                text: 'Get Started',
                width: 220.w,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AICaptureScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
