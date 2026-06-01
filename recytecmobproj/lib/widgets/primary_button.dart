import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/recytechtheme.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool filled;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.filled = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? double.infinity;

    final ButtonStyle style = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: RecyTechTheme.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                RecyTechTheme.secondary.withValues(alpha: 0.24),
            disabledForegroundColor: Colors.white70,
            minimumSize: Size(w, 48.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            elevation: 0,
            textStyle: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: RecyTechTheme.primary,
            backgroundColor: RecyTechTheme.pill,
            side: const BorderSide(color: RecyTechTheme.border, width: 1),
            minimumSize: Size(w, 48.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            textStyle: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
            ),
          );

    return SizedBox(
      width: w,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed, style: style, child: Text(text))
          : OutlinedButton(
              onPressed: onPressed, style: style, child: Text(text)),
    );
  }
}
