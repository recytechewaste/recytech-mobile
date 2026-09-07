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
    final accent = color ?? _colorFor(context, label);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
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

  Color _colorFor(BuildContext context, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final danger = isDark ? const Color(0xFFFF8A80) : RecyTechTheme.danger;
    final warning = isDark ? const Color(0xFFFFC66D) : RecyTechTheme.warning;
    final success = isDark ? const Color(0xFF63DBA8) : RecyTechTheme.success;
    final info = isDark ? const Color(0xFF79D9B8) : scheme.primary;
    final value = status.trim().toLowerCase().replaceAll('_', ' ');
    if (value.contains('cancel') ||
        value.contains('reject') ||
        value.contains('inactive') ||
        value.contains('offline') ||
        value.contains('error')) {
      return danger;
    }
    if (value.contains('full') ||
        value.contains('delay') ||
        value.contains('inspect') ||
        value.contains('pending') ||
        value.contains('queued') ||
        value.contains('assigned') ||
        value.contains('way') ||
        value.contains('arrived') ||
        value.contains('progress')) {
      return warning;
    }
    if (value.contains('complete') ||
        value.contains('active') ||
        value.contains('online') ||
        value.contains('current') ||
        value == 'empty') {
      return success;
    }

    final requestStatus = CollectionRequestStatuses.normalize(status);
    if (requestStatus == CollectionRequestStatuses.completed) {
      return info;
    }
    if (requestStatus == CollectionRequestStatuses.approved ||
        requestStatus == CollectionRequestStatuses.collectorAssigned ||
        requestStatus == CollectionRequestStatuses.onTheWay ||
        requestStatus == CollectionRequestStatuses.arrived ||
        requestStatus == CollectionRequestStatuses.inProgress) {
      return warning;
    }
    if (requestStatus == CollectionRequestStatuses.cancelled ||
        requestStatus == CollectionRequestStatuses.rejected) {
      return danger;
    }
    return scheme.onSurfaceVariant;
  }
}
