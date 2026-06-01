import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/data/models/user_model.dart';
import 'package:recytecmobproj/presentation/auth/login_screen.dart';
import 'package:recytecmobproj/services/auth_provider.dart';

class CollectorProfileScreen extends StatefulWidget {
  const CollectorProfileScreen({super.key});

  @override
  State<CollectorProfileScreen> createState() => _CollectorProfileScreenState();
}

class _CollectorProfileScreenState extends State<CollectorProfileScreen> {
  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.route,
      (route) => false,
    );
  }

  String _displayName(UserModel? user) {
    if (user == null) return 'Collector';

    final fullName = user.fullName.trim();
    if (fullName.isNotEmpty) return fullName;

    final composedName = [
      user.firstName,
      user.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    if (composedName.isNotEmpty) return composedName;

    final email = user.email.trim();
    if (email.isNotEmpty) return email.split('@').first;

    return 'Collector';
  }

  String _profileValue(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Not set' : text;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final displayName = _displayName(user);

    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(
        title: const Text('Collector Profile'),
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),

            // 🔹 PROFILE ICON
            CircleAvatar(
              radius: 40.r,
              backgroundColor: RecyTechTheme.pill,
              child: Icon(
                Icons.person,
                size: 40.sp,
                color: RecyTechTheme.primary,
              ),
            ),

            SizedBox(height: 12.h),

            // 🔹 NAME & ROLE
            Text(
              displayName,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: RecyTechTheme.textDark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'E-Waste Collector',
              style: TextStyle(
                fontSize: 12.sp,
                color: RecyTechTheme.textMuted,
              ),
            ),

            SizedBox(height: 30.h),

            _profileItem('Vehicle Type', _profileValue(user?.vehicleType)),
            _profileItem('Plate Number', _profileValue(user?.plateNumber)),
            if (user?.email.trim().isNotEmpty == true)
              _profileItem(
                'Account Email',
                user!.email.trim(),
                secondary: true,
              ),

            const Spacer(),

            // 🔹 LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: auth.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : OutlinedButton(
                      onPressed: _logout,
                      child: const Text('Logout'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(
    String label,
    String value, {
    bool secondary = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: RecyTechTheme.border),
        boxShadow: [
          BoxShadow(
            color: RecyTechTheme.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: RecyTechTheme.textMuted,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: secondary ? 11.sp : 12.sp,
                color: secondary
                    ? RecyTechTheme.textMuted
                    : RecyTechTheme.textDark,
                fontWeight: secondary ? FontWeight.w600 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
