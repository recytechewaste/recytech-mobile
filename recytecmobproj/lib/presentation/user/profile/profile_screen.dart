import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/data/models/user_model.dart';
import 'package:recytecmobproj/services/auth_provider.dart';

import '../../../widgets/primary_button.dart';
import '../contributions/contribution_screen.dart';
import '../../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _profileImage = File(picked.path);
    });
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
        SizedBox(height: 2.h),
        Text(label,
            style: TextStyle(fontSize: 10.sp, color: RecyTechTheme.textMuted)),
      ],
    );
  }

  Widget _recentRow(String title, String date, String status) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 2.h),
                Text(date,
                    style: TextStyle(
                        fontSize: 9.5.sp, color: RecyTechTheme.textMuted)),
              ],
            ),
          ),
          Text(status,
              style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _displayName(UserModel? user) {
    if (user == null) return 'User';

    final fullName = user.fullName.trim();
    if (fullName.isNotEmpty) return fullName;

    final composedName = [
      user.firstName,
      user.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    if (composedName.isNotEmpty) return composedName;

    final email = user.email.trim();
    if (email.isNotEmpty) return email.split('@').first;

    return 'User';
  }

  String _profileValue(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Not set' : text;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final displayName = _displayName(user);

    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Profile'),
          actions: const [
            Icon(Icons.search),
            SizedBox(width: 12),
            Icon(Icons.more_vert),
            SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          children: [
            Text('My Profile',
                style:
                    TextStyle(fontSize: 12.sp, color: RecyTechTheme.textMuted)),
            SizedBox(height: 10.h),

            // ✅ CLICKABLE PROFILE IMAGE
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48.r,
                      backgroundColor: cs.primary.withValues(alpha: 0.12),
                      foregroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? Icon(Icons.person, size: 42.sp, color: cs.primary)
                          : null,
                    ),
                    Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.camera_alt,
                          size: 16.sp, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10.h),

            Center(
              child: Text(
                displayName,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(height: 8.h),

            Center(
                child: Text('Top Contributor',
                    style: TextStyle(
                        fontSize: 10.sp, color: RecyTechTheme.textMuted))),
            SizedBox(height: 8.h),

            _profileInfoCard('Email Address', _profileValue(user?.email), cs),
            SizedBox(height: 8.h),
            _profileInfoCard('Contact Number', _profileValue(user?.phone), cs),

            SizedBox(height: 14.h),
            const Divider(),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('78', 'Contributions'),
                  _stat('56', 'Recycles'),
                  _stat('45', 'Requests'),
                ],
              ),
            ),

            const Divider(),
            SizedBox(height: 12.h),

            Center(
                child: Text('Recent Contributions',
                    style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w900))),
            SizedBox(height: 10.h),

            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                border: Border.all(color: RecyTechTheme.border),
                borderRadius: BorderRadius.circular(20.r),
                color: Colors.white,
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
                  _recentRow('Old Laptop', 'July 23, 2025', 'Completed'),
                  const Divider(),
                  _recentRow('Tablet', 'Aug 25, 2025', 'Completed'),
                ],
              ),
            ),

            SizedBox(height: 10.h),
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContributionScreen()),
                ),
                child: Text(
                  'View all contributions >',
                  style: TextStyle(fontSize: 10.5.sp),
                ),
              ),
            ),

            SizedBox(height: 14.h),
            Center(
              child: auth.isLoading
                  ? SizedBox(
                      width: 220.w,
                      height: 44.h,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : PrimaryButton(
                      text: 'Logout',
                      filled: false,
                      width: 220.w,
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;

                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          LoginScreen.route,
                          (route) => false,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileInfoCard(String label, String value, ColorScheme cs) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: RecyTechTheme.border),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.sp,
                color: RecyTechTheme.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
