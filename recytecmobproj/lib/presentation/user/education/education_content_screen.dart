import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/recytechtheme.dart';
import 'education_content_detail_screen.dart';
import 'education_content_item.dart';

class EducationContentScreen extends StatelessWidget {
  const EducationContentScreen({super.key});

  // TODO: Replace this placeholder list with backend educational content when
  // the education API/repository is available for the mobile app.
  static const List<EducationContentItem> _items = [
    EducationContentItem(
      title: 'What is E-Waste?',
      summary:
          'A simple guide to common electronic waste items and why they need proper handling.',
      category: 'Basics',
      dateLabel: 'Learning guide',
      body:
          'E-waste is discarded electrical or electronic equipment such as phones, laptops, chargers, batteries, monitors, and appliances. These items can contain reusable metals and parts, but they may also contain materials that should not end up in ordinary trash.\n\nProper e-waste handling helps recover valuable resources, keeps hazardous parts away from soil and water, and supports safer recycling practices.',
    ),
    EducationContentItem(
      title: 'Why Proper E-Waste Disposal Matters',
      summary:
          'Learn how responsible disposal protects communities and the environment.',
      category: 'Environment',
      dateLabel: 'Learning guide',
      body:
          'Electronic waste can release harmful substances when it is burned, dumped, or dismantled without care. Proper disposal sends items to collection and recycling channels that can separate reusable materials from parts that need safer treatment.\n\nChoosing responsible disposal reduces landfill waste, lowers pollution risk, and helps communities build cleaner collection habits.',
    ),
    EducationContentItem(
      title: 'How RecyTech Drop-Off Works',
      summary:
          'Find a designated bin, then submit your e-waste category and quantity.',
      category: 'RecyTech',
      dateLabel: 'Learning guide',
      body:
          'Household users bring accepted e-waste to designated RecyTech bins in approved buildings, communities, and facilities. Use the Bin Locator to find a bin, view its location on the map, and submit a drop-off with the category and quantity accepted by that bin.\n\nScanning the QR code identifies the bin before opening the same drop-off form. Later collection, item verification, and points processing are handled through future RecyTech workflows.',
    ),
    EducationContentItem(
      title: 'Preparing Items for a Designated Bin',
      summary:
          'Practical reminders before bringing old electronics to a drop-off bin.',
      category: 'Safety',
      dateLabel: 'Learning guide',
      body:
          'Before bringing e-waste to a designated bin, keep items dry and avoid breaking batteries, screens, or circuit boards. If an item is swollen, leaking, sharp, or damaged, handle it carefully and keep it away from children.\n\nRemove personal data from devices when possible, bundle small accessories together, and follow the access instructions shown for the selected RecyTech bin.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: RecyTechTheme.bg,
        appBar: AppBar(
          title: const Text('Environmental Impact'),
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          children: [
            Text(
              'Educational Content',
              style: TextStyle(
                color: RecyTechTheme.textDark,
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Read simple guides about e-waste, designated bins, and safer handling.',
              style: TextStyle(
                color: RecyTechTheme.textMuted,
                fontSize: 11.sp,
                height: 1.35,
              ),
            ),
            SizedBox(height: 14.h),
            for (final item in _items) ...[
              _EducationContentCard(item: item),
              SizedBox(height: 12.h),
            ],
          ],
        ),
      ),
    );
  }
}

class _EducationContentCard extends StatelessWidget {
  final EducationContentItem item;

  const _EducationContentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EducationContentDetailScreen(item: item),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: RecyTechTheme.border),
          boxShadow: [
            BoxShadow(
              color: RecyTechTheme.primary.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: RecyTechTheme.pill,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                color: RecyTechTheme.primary,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: RecyTechTheme.textDark,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: RecyTechTheme.textMuted,
                      fontSize: 11.sp,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      _MetaPill(text: item.category),
                      _MetaPill(text: item.dateLabel),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right,
              color: RecyTechTheme.textMuted,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String text;

  const _MetaPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: RecyTechTheme.pill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: RecyTechTheme.primary,
          fontSize: 9.5.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
