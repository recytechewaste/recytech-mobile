import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../data/models/user_model.dart';
import '../../../services/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/recytechtheme.dart';
import '../../notifications/notification_center_screen.dart';
import '../bins/bin_locator_screen.dart';
import '../bins/bin_qr_scanner_screen.dart';
import '../history/history_screen.dart';
import '../rewards/rewards_screen.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  static Color get _primary => RecyTechTheme.primary;
  static Color get _bg => RecyTechTheme.bg;
  static Color get _textDark => RecyTechTheme.textDark;
  static Color get _textMuted => RecyTechTheme.textMuted;
  static Color get _border => RecyTechTheme.border;

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
          color: RecyTechTheme.card,
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
            Icon(
              Icons.chevron_right,
              color: RecyTechTheme.textMuted,
              size: 20.sp,
            ),
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
              'Find a designated bin, scan its QR code, and submit e-waste drop-offs.',
              style: TextStyle(fontSize: 11.sp, color: _textMuted),
            ),
            SizedBox(height: 16.h),
            _infoCard(
              title: 'Find a Bin',
              body:
                  'Locate designated RecyTech bins and view their mapped locations.',
              icon: Icons.location_on_outlined,
              tint: _primary,
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
              title: 'Scan Bin QR',
              body:
                  'Identify the bin, then submit your e-waste category and quantity.',
              icon: Icons.qr_code_scanner,
              tint: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BinQrScannerScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 12.h),
            _infoCard(
              title: 'Rewards',
              body: 'View available partner rewards and your points activity.',
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
              title: 'Drop-Off History',
              body: 'Review manual and QR drop-off submissions.',
              icon: Icons.history,
              tint: Colors.blueGrey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
