import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/bin_monitoring_models.dart';

class DepositEventCard extends StatelessWidget {
  const DepositEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  final DepositEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final detection = event.bestDetection;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RecyTechTheme.border),
        ),
        child: Row(
          children: [
            CapturedObjectImage(imageUrl: event.imageUrl, size: 58.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detection?.objectClass ?? 'No detected object',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: RecyTechTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  MappedCategoryLabel(
                    label: detection?.mappedCategory ?? 'Unmapped e-waste',
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    formatDateTime(event.capturedAt),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: RecyTechTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            DetectionConfidenceChip(
              confidence: detection?.confidence,
              lowConfidence: event.isLowConfidence,
            ),
          ],
        ),
      ),
    );
  }
}

class DetectionConfidenceChip extends StatelessWidget {
  const DetectionConfidenceChip({
    super.key,
    required this.confidence,
    this.lowConfidence = false,
  });

  final double? confidence;
  final bool lowConfidence;

  @override
  Widget build(BuildContext context) {
    final color = lowConfidence ? RecyTechTheme.warning : RecyTechTheme.primary;
    final text = confidence == null
        ? 'No score'
        : '${(confidence! * 100).toStringAsFixed(0)}%';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class CapturedObjectImage extends StatelessWidget {
  const CapturedObjectImage({
    super.key,
    required this.imageUrl,
    this.size,
    this.height,
    this.width,
  });

  final String? imageUrl;
  final double? size;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl?.trim() ?? '';
    final h = height ?? size ?? 92.h;
    final w = width ?? size ?? double.infinity;

    Widget child;
    if (image.startsWith('asset:')) {
      child = Image.asset(
        image.substring('asset:'.length),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else if (image.startsWith('http://') || image.startsWith('https://')) {
      child = Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      child = _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: w,
        height: h,
        child: child,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: RecyTechTheme.pill,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: RecyTechTheme.textMuted,
      ),
    );
  }
}

class MappedCategoryLabel extends StatelessWidget {
  const MappedCategoryLabel({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11.sp,
        color: RecyTechTheme.textMuted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class LowConfidenceWarning extends StatelessWidget {
  const LowConfidenceWarning({
    super.key,
    this.message =
        'Low-confidence recommendation. Preserve the prediction and verify during authorized review.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final warning = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFC66D)
        : RecyTechTheme.warning;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warning.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: warning, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11.sp,
                height: 1.35,
                color: warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({
    super.key,
    required this.label,
    required this.status,
    this.icon,
  });

  final String label;
  final String status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = status.toLowerCase().contains('online')
        ? RecyTechTheme.primary
        : status.toLowerCase().contains('delayed')
            ? RecyTechTheme.warning
            : RecyTechTheme.danger;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.sensors_outlined, color: color, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: RecyTechTheme.textMuted),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 11.sp,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class FillLevelIndicator extends StatelessWidget {
  const FillLevelIndicator({
    super.key,
    required this.fillLevel,
    required this.status,
  });

  final double? fillLevel;
  final String status;

  @override
  Widget build(BuildContext context) {
    final value = ((fillLevel ?? 0) / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: RecyTechTheme.textDark,
                ),
              ),
            ),
            Text(
              fillLevel == null ? 'No sensor' : '${fillLevel!.round()}%',
              style: TextStyle(
                fontSize: 12.sp,
                color: RecyTechTheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10.h,
            value: fillLevel == null ? null : value,
            backgroundColor: RecyTechTheme.pill,
            valueColor: AlwaysStoppedAnimation<Color>(
              value >= 0.80 ? RecyTechTheme.warning : RecyTechTheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class DetectionHistoryTimeline extends StatelessWidget {
  const DetectionHistoryTimeline({
    super.key,
    required this.events,
    required this.onOpenEvent,
  });

  final List<DepositEvent> events;
  final void Function(DepositEvent event) onOpenEvent;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _empty('No inlet-camera deposit events recorded yet.');
    }

    return Column(
      children: events
          .map(
            (event) => DepositEventCard(
              event: event,
              onTap: () => onOpenEvent(event),
            ),
          )
          .toList(),
    );
  }

  Widget _empty(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 12.sp, color: RecyTechTheme.textMuted),
      ),
    );
  }
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '-';
  final local = dateTime.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}
