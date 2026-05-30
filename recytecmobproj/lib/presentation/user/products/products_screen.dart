import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../rewards/rewards_screen.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Text(
              'Our Products',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: _ProductTile(
                    title: 'Smart Recycling Bin',
                    subtitle: 'Data on usage',
                    onTap: () {},
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _ProductTile(
                    title: 'E-Waste Reports',
                    subtitle: 'User access',
                    onTap: () {},
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _ProductTile(
                    title: 'Pickup Tracking',
                    subtitle: 'Track collector',
                    onTap: () {},
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _ProductTile(
                    title: 'Rewards',
                    subtitle: 'Earn points',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RewardsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProductTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black12.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            SizedBox(height: 10.h),
            Text(title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 4.h),
            Text(subtitle, style: TextStyle(fontSize: 10.sp, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
