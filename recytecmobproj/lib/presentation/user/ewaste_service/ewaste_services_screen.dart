import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:recytecmobproj/presentation/user/contributions/contribution_screen.dart';
import 'package:recytecmobproj/presentation/user/history/history_screen.dart';
import 'package:recytecmobproj/presentation/user/profile/profile_screen.dart';
import 'package:recytecmobproj/widgets/ui_components.dart';

import 'submission_form_screen.dart';
import 'tracking_screen.dart';

class EWasteServicesScreen extends StatelessWidget {
  const EWasteServicesScreen({super.key});

  // 🌱 RecyTech color palette
  static const Color _primary = Color(0xFF1B5E20); // eco green
  static const Color _secondary = Color(0xFF00897B); // teal
  static const Color _accent = Color(0xFFF9A825); // amber
  static const Color _bg = Color(0xFFF5F7F4);
  static const Color _textDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('E-Waste Services'),
        centerTitle: true,
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textDark,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // 🔹 HEADER CARD
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit & Manage Requests',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Choose an action below to manage your electronic waste responsibly.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // 🔹 PRIMARY ACTION
          _serviceButton(
            context,
            label: 'E-Waste Submission Form',
            icon: Icons.upload_file,
            color: _primary,
            filled: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubmissionFormScreen()),
            ),
          ),

          SizedBox(height: 12.h),

          // 🔹 SECONDARY ACTIONS
          _serviceButton(
            context,
            label: 'AI-Based Identification',
            icon: Icons.center_focus_strong,
            color: _secondary,
            filled: false,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubmissionFormScreen()),
            ),
          ),

          SizedBox(height: 12.h),

          _serviceButton(
            context,
            label: 'Tracking Page',
            icon: Icons.location_on_outlined,
            color: const Color(0xFF6D28D9), // subtle purple
            filled: false,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrackingScreen()),
            ),
          ),

          SizedBox(height: 12.h),

          _serviceButton(
            context,
            label: 'History',
            icon: Icons.history,
            color: _accent,
            filled: false,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),

          SizedBox(height: 12.h),

          _serviceButton(
            context,
            label: 'Profile',
            icon: Icons.person_outline,
            color: Colors.blueGrey,
            filled: false,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),

          SizedBox(height: 12.h),

          _serviceButton(
            context,
            label: 'Contributions Page',
            icon: Icons.volunteer_activism,
            color: const Color(0xFF16A34A), // green accent
            filled: false,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContributionScreen()),
            ),
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // 🔹 CUSTOM SERVICE BUTTON (consistent look)
  Widget _serviceButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: filled ? 1 : 0,
          backgroundColor: filled ? color : Colors.white,
          foregroundColor: filled ? Colors.white : _textDark,
          side: filled
              ? BorderSide.none
              : BorderSide(color: color.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: filled ? Colors.white : color, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: filled ? Colors.white70 : Colors.black38,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
