import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/recytechtheme.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool? enableSuggestions;
  final bool? autocorrect;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int maxLines;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enableSuggestions,
    this.autocorrect,
    this.textInputAction,
    this.autofillHints,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: RecyTechTheme.textDark,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType:
              obscureText ? TextInputType.visiblePassword : keyboardType,
          obscureText: obscureText,
          enableSuggestions: enableSuggestions ?? !obscureText,
          autocorrect: autocorrect ?? !obscureText,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: RecyTechTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide:
                  const BorderSide(color: RecyTechTheme.primary, width: 1.6),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }
}
