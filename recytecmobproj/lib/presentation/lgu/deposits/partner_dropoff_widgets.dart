import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import '../../../data/models/drop_off_record_model.dart';

class PartnerDropOffImage extends StatelessWidget {
  const PartnerDropOffImage({
    super.key,
    required this.source,
    this.height,
    this.width,
    this.borderRadius = 14,
  });

  final String? source;
  final double? height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = _image();
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: width,
        child: image ?? _placeholder(),
      ),
    );
  }

  Widget? _image() {
    final value = source?.trim() ?? '';
    if (value.isEmpty) return null;

    if (value.startsWith('data:image/') && value.contains(';base64,')) {
      final encoded = value.substring(value.indexOf(',') + 1);
      if (encoded.isEmpty || encoded.length > 16 * 1024 * 1024) return null;
      try {
        final Uint8List bytes = base64Decode(encoded);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } on FormatException {
        return null;
      }
    }

    final uri = Uri.tryParse(value);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: RecyTechTheme.pill,
            alignment: Alignment.center,
            child: SizedBox.square(
              dimension: 22.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }
    return null;
  }

  Widget _placeholder() {
    return Container(
      color: RecyTechTheme.pill,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: RecyTechTheme.textMuted,
        size: 30.sp,
      ),
    );
  }
}

String dropOffCategory(DropOffRecord record) {
  if (record.items.isEmpty) return 'E-waste item';
  final item = record.items.first;
  final label = item.categoryLabel?.trim() ?? '';
  return label.isNotEmpty ? label : _titleCase(item.category);
}

String dropOffQuantity(DropOffRecord record) {
  final total = record.items.fold<num>(0, (sum, item) => sum + item.quantity);
  final value = total % 1 == 0 ? total.toInt().toString() : total.toString();
  return '$value item${total == 1 ? '' : 's'}';
}

String dropOffDate(DateTime value) {
  if (value.millisecondsSinceEpoch == 0) return 'Date unavailable';
  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${months[local.month - 1]} ${local.day}, ${local.year} · '
      '$hour:$minute $period';
}

String _titleCase(String value) => value
    .trim()
    .replaceAll(RegExp(r'[_-]+'), ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => part.toUpperCase() == 'PCB'
        ? 'PCB'
        : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
    .join(' ');
