import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/theme/recytechtheme.dart';
import '../../services/auth_provider.dart';
import '../auth/login_screen.dart';

class AccessDeniedScreen extends StatelessWidget {
  static const route = '/unsupported-role';

  const AccessDeniedScreen({
    super.key,
    this.role,
  });

  final String? role;

  @override
  Widget build(BuildContext context) {
    final displayRole = (role ?? '').trim().isEmpty ? 'Unknown' : role!.trim();

    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58.w,
                  height: 58.w,
                  decoration: BoxDecoration(
                    color: RecyTechTheme.pill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    color: RecyTechTheme.primary,
                    size: 30.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Role Not Supported',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'This mobile app currently supports Household, Partner Organization, and Collector accounts. Your account role is $displayRole.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
                SizedBox(height: 18.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        LoginScreen.route,
                        (_) => false,
                      );
                    },
                    child: const Text('Back to Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
