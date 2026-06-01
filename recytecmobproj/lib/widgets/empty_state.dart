import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/recytechtheme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    this.icon = Icons.eco_outlined,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: RecyTechTheme.border),
        boxShadow: [
          BoxShadow(
            color: RecyTechTheme.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: const BoxDecoration(
              color: RecyTechTheme.pill,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: RecyTechTheme.primary, size: 24.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RecyTechTheme.textDark,
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (message != null && message!.trim().isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RecyTechTheme.textMuted,
                fontSize: 11.sp,
                height: 1.35,
              ),
            ),
          ],
          if (action != null) ...[
            SizedBox(height: 12.h),
            action!,
          ],
        ],
      ),
    );
  }
}
