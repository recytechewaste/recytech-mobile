import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Support')),
        body: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            Text(
              'Help & Support',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12.h),

            _SupportTile(
              icon: Icons.question_answer_outlined,
              title: 'FAQs',
              subtitle: 'Common questions and answers',
              onTap: () {},
            ),
            _SupportTile(
              icon: Icons.call_outlined,
              title: 'Contact Support',
              subtitle: 'Reach out to our team',
              onTap: () {},
            ),
            _SupportTile(
              icon: Icons.report_outlined,
              title: 'Report an Issue',
              subtitle: 'Send a problem report',
              onTap: () {},
            ),
            _SupportTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy & Policy',
              subtitle: 'View policies',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black54),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2.h),
                    Text(subtitle, style: TextStyle(fontSize: 10.sp, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
