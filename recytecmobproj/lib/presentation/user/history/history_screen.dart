import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<HistoryScreen> {
  int tabIndex = 0;

  final tabs = const ['Pending', 'Completed (Pickup History)', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          actions: const [
            Icon(Icons.search),
            SizedBox(width: 12),
            Icon(Icons.more_vert),
            SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          children: [
            Text('My History', style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
            SizedBox(height: 10.h),

            Center(
              child: Text('My Requests & Pickup History',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
            ),
            SizedBox(height: 6.h),
            Center(
              child: Text(
                'Here you can view all your submitted e-waste requests. Once a pickup is marked as Collected, it will appear under Completed (Pickup History).',
                style: TextStyle(fontSize: 10.sp, color: Colors.black54),
              ),
            ),
            SizedBox(height: 10.h),

            // Tabs row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(tabs.length, (i) {
                final selected = i == tabIndex;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ChoiceChip(
                    label: Text(tabs[i], style: TextStyle(fontSize: 10.sp)),
                    selected: selected,
                    onSelected: (_) => setState(() => tabIndex = i),
                    selectedColor: Colors.black12,
                    backgroundColor: Colors.white,
                    shape: StadiumBorder(side: BorderSide(color: Colors.black12, width: 1.w)),
                    labelPadding: EdgeInsets.symmetric(horizontal: 10.w),
                  ),
                );
              }),
            ),
            SizedBox(height: 14.h),

            Center(
              child: Text(
                tabIndex == 1 ? 'Pickup History (Completed Requests)' : 'Submitted E-Waste Requests',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(height: 4.h),
            Center(
              child: Text(
                'A list of all your requests with their status.',
                style: TextStyle(fontSize: 9.5.sp, color: Colors.black54),
              ),
            ),
            SizedBox(height: 14.h),

            _requestRow(icon: Icons.person_outline, label: 'Request ID', value: '12345'),
            _divider(),
            _requestRow(icon: Icons.devices_other, label: 'E-Waste Type', value: 'Old Computer'),
            _divider(),
            _requestRow(icon: Icons.event_note_outlined, label: 'Submission Date', value: '2023-10-01'),
            _divider(),
            _requestRow(
                icon: Icons.show_chart,
                label: 'Status',
                value: tabIndex == 0
                    ? 'Pending'
                    : tabIndex == 1
                        ? 'Collected'
                        : 'Cancelled'),
            _divider(),
            _requestRow(
                icon: Icons.touch_app_outlined,
                label: 'Action',
                value: tabIndex == 1 ? 'View Receipt & Rewards' : 'View Details'),
            _divider(),
            _requestRow(icon: Icons.badge_outlined, label: 'Collector', value: 'Juan Dela Cruz'),

            SizedBox(height: 18.h),
            Center(child: Text('© 2026 My E-Waste Management System', style: TextStyle(fontSize: 9.sp, color: Colors.black38))),
            SizedBox(height: 4.h),
            Center(child: Text('All rights reserved.', style: TextStyle(fontSize: 9.sp, color: Colors.black38))),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: const Divider(height: 1, color: Colors.black12),
      );

  Widget _requestRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: Colors.black54),
        SizedBox(width: 10.w),
        Expanded(child: Text(label, style: TextStyle(fontSize: 11.sp))),
        Text(value, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
