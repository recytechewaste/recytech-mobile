import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final displayName =
        user?.fullName.trim().isNotEmpty == true ? user!.fullName : 'Collector';

    return Scaffold(
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
              backgroundColor: Colors.grey.shade300,
              child: Icon(
                Icons.person,
                size: 40.sp,
                color: const Color.fromARGB(137, 1, 186, 26),
              ),
            ),

            SizedBox(height: 12.h),

            // 🔹 NAME & ROLE
            Text(
              displayName,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'E-Waste Collector',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black54,
              ),
            ),

            SizedBox(height: 30.h),

            // 🔹 PROFILE DETAILS
            _profileItem('Assigned Barangay', 'Marikina Heights'),
            _profileItem('Collector ID', user?.id ?? '-'),
            _profileItem('Contact Number', '0912 345 6789'),

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

  Widget _profileItem(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(31, 5, 166, 21)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
