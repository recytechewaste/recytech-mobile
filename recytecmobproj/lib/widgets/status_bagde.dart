import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/app_constants.dart';
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
    final requestStatus = CollectionRequestStatuses.normalize(status);
    if (requestStatus == CollectionRequestStatuses.completed) {
      return RecyTechTheme.primary;
    }
    if (requestStatus == CollectionRequestStatuses.approved ||
        requestStatus == CollectionRequestStatuses.collectorAssigned ||
        requestStatus == CollectionRequestStatuses.onTheWay ||
        requestStatus == CollectionRequestStatuses.arrived ||
        requestStatus == CollectionRequestStatuses.inProgress) {
      return RecyTechTheme.accent;
    }
    if (requestStatus == CollectionRequestStatuses.cancelled ||
        requestStatus == CollectionRequestStatuses.rejected) {
      return Colors.redAccent;
    }
    return RecyTechTheme.secondary;
  }
}
