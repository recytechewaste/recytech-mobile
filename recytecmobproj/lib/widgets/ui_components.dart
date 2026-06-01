import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/recytechtheme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = filled
        ? ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 48.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r)),
          )
        : OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, 48.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r)),
          );

    return filled
        ? ElevatedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton(
            onPressed: onPressed, style: style, child: Text(label));
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool? enableSuggestions;
  final bool? autocorrect;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int maxLines;

  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.enableSuggestions,
    this.autocorrect,
    this.textInputAction,
    this.autofillHints,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
            color: RecyTechTheme.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 13.sp,
          )),
      SizedBox(height: 6.h),
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: obscure ? TextInputType.visiblePassword : keyboardType,
        enableSuggestions: enableSuggestions ?? !obscure,
        autocorrect: autocorrect ?? !obscure,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r)),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        ),
      ),
    ]);
  }
}

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const SectionTitle({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: RecyTechTheme.primary),
        SizedBox(width: 8.w),
        Text(title,
            style: TextStyle(
              color: RecyTechTheme.textDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const SoftCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: RecyTechTheme.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 6),
            color: RecyTechTheme.primary.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: child,
    );
  }
}
