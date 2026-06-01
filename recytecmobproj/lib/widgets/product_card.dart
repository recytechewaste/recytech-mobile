import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/recytechtheme.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.devices_other_outlined,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: RecyTechTheme.border),
          boxShadow: [
            BoxShadow(
              color: RecyTechTheme.primary.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: RecyTechTheme.pill,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(icon, color: RecyTechTheme.primary, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: RecyTechTheme.textDark,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: RecyTechTheme.textMuted,
                      fontSize: 11.sp,
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
}
