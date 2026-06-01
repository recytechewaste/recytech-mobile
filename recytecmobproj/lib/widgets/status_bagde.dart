import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/recytechtheme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? _colorFor(label);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _colorFor(String status) {
    final value = status.toLowerCase();
    if (value.contains('completed') || value.contains('collected')) {
      return RecyTechTheme.primary;
    }
    if (value.contains('approved') ||
        value.contains('transit') ||
        value.contains('accepted')) {
      return RecyTechTheme.accent;
    }
    if (value.contains('cancel') || value.contains('decline')) {
      return Colors.redAccent;
    }
    return RecyTechTheme.secondary;
  }
}
