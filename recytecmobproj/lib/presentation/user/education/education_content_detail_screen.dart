import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import 'education_content_item.dart';

class EducationContentDetailScreen extends StatelessWidget {
  final EducationContentItem item;

  const EducationContentDetailScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Educational Content'),
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: RecyTechTheme.card,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(color: RecyTechTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: RecyTechTheme.primary.withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: RecyTechTheme.pill,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: RecyTechTheme.border),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        color: RecyTechTheme.primary,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    item.title,
                    style: TextStyle(
                      color: RecyTechTheme.textDark,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    item.dateLabel,
                    style: TextStyle(
                      color: RecyTechTheme.textMuted,
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    item.body,
                    style: TextStyle(
                      color: RecyTechTheme.textDark,
                      fontSize: 12.sp,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
