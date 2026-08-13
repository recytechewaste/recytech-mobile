import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../data/models/user_model.dart';
import '../../../services/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../notifications/notification_center_screen.dart';
import '../bins/bin_locator_screen.dart';
import '../education/education_content_screen.dart';
import '../ewaste_service/submission_form_screen.dart';
import '../history/history_screen.dart';
import '../rewards/rewards_screen.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  static const _primary = Color(0xFF1F4D36);
  static const _accent = Color(0xFFE5A823);
  static const _bg = Color(0xFFF7FAF5);
  static const _textDark = Color(0xFF1B1F1D);
  static const _textMuted = Color(0xFF66736A);
  static const _border = Color(0xFFE3EBE2);

  Widget _infoCard({
    required String title,
    required String body,
    required IconData icon,
    required Color tint,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16.r),
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
                      color: _textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.black38, size: 20.sp),
          ],
        ),
      ),
    );
  }

  String _firstName(UserModel? user) {
    if (user == null) return 'User';

    final firstName = user.firstName.trim();
    if (firstName.isNotEmpty) return firstName;

    final fullName = user.fullName.trim();
    if (fullName.isNotEmpty) return fullName.split(RegExp(r'\s+')).first;

    final email = user.email.trim();
    if (email.isNotEmpty) return email.split('@').first;

    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName(context.watch<AuthProvider>().currentUser);

    return SafeArea(
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('Dashboard'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationCenterScreen(
                      role: UserRole.household,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          children: [
            Text(
              'Hi, $firstName!',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Manage your e-waste responsibly today',
              style: TextStyle(fontSize: 11.sp, color: _textMuted),
            ),
            SizedBox(height: 16.h),
            _infoCard(
              title: 'Submit E-Waste',
              body: 'Manually enter item details and request information.',
              icon: Icons.send_outlined,
              tint: _primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubmissionFormScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 12.h),
            _infoCard(
              title: 'Bin Locator',
              body: 'Find designated public drop-off points and directions.',
              icon: Icons.location_on_outlined,
              tint: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BinLocatorScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 12.h),
            _infoCard(
              title: 'Rewards',
              body: 'View contribution payouts where backend data exists.',
              icon: Icons.emoji_events_outlined,
              tint: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RewardsScreen()),
                );
              },
            ),
            SizedBox(height: 12.h),
            _infoCard(
              title: 'History',
              body: 'Review submitted requests and backend status history.',
              icon: Icons.history,
              tint: Colors.blueGrey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            SizedBox(height: 12.h),
            _infoCard(
              title: 'Environmental Impact',
              body: 'Learn how e-waste recycling helps the environment.',
              icon: Icons.public,
              tint: _accent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EducationContentScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
