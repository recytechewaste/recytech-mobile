import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/recytechtheme.dart';

class HomeFeatureCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const HomeFeatureCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: RecyTechTheme.border),
        boxShadow: [
          BoxShadow(
            color: RecyTechTheme.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🔹 IMAGE PLACEHOLDER
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: RecyTechTheme.pill,
              borderRadius: BorderRadius.circular(16.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),

          SizedBox(width: 12.w),

          // 🔹 TEXT CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: RecyTechTheme.textDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: RecyTechTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
