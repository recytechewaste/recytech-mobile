import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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
        Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.black54)),
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
                    style: TextStyle(fontSize: 9.5.sp, color: Colors.black54)),
              ],
            ),
          ),
          Text(status,
              style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();

    return SafeArea(
      child: Scaffold(
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
                style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
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
                'Juan Dela Cruz',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(height: 2.h),
            Center(
                child: Text('Marikina City',
                    style: TextStyle(fontSize: 10.sp, color: Colors.black54))),
            SizedBox(height: 8.h),

            Center(
                child: Text('Top Contributor',
                    style: TextStyle(fontSize: 10.sp, color: Colors.black54))),
            SizedBox(height: 8.h),

            Center(
              child: Wrap(
                spacing: 10.w,
                children: [
                  _pill('Email Address', cs),
                  _pill('Contact Number', cs),
                ],
              ),
            ),

            SizedBox(height: 14.h),
            const Divider(color: Colors.black12),

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

            const Divider(color: Colors.black12),
            SizedBox(height: 12.h),

            Center(
                child: Text('Recent Contributions',
                    style: TextStyle(
                        fontSize: 11.sp, fontWeight: FontWeight.w900))),
            SizedBox(height: 10.h),

            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12.r),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  _recentRow('Old Laptop', 'July 23, 2025', 'Completed'),
                  const Divider(color: Colors.black12),
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

  Widget _pill(String text, ColorScheme cs) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10.sp, color: cs.onSurface)),
    );
  }
}
