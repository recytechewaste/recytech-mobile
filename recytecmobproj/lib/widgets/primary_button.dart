import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: Size(w, 44.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            elevation: 0,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black, width: 1),
            minimumSize: Size(w, 44.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          );

    return SizedBox(
      width: w,
      child: filled
          ? ElevatedButton(onPressed: onPressed, style: style, child: Text(text))
          : OutlinedButton(onPressed: onPressed, style: style, child: Text(text)),
    );
  }
}
