import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ContributionScreen extends StatelessWidget {
  const ContributionScreen({super.key});

  Widget _row(String title, String date, String status) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900)),
              SizedBox(height: 2.h),
              Text(date, style: TextStyle(fontSize: 9.5.sp, color: Colors.black54)),
            ]),
          ),
          Text(status, style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contributions Page'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
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
            Center(
              child: Text(
                "Juan's Contributions",
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(height: 4.h),
            Center(
              child: Text(
                'Total Items Recycled: 78',
                style: TextStyle(fontSize: 10.5.sp, color: Colors.black54),
              ),
            ),
            SizedBox(height: 14.h),

            _row('Old Laptop', 'May 14, 2025', 'Completed'),
            const Divider(color: Colors.black12),
            _row('Tablet', 'June 20, 2025', 'Completed'),
            const Divider(color: Colors.black12),
            _row('Desktop Computer', 'September 25, 2025', 'Completed'),
            const Divider(color: Colors.black12),
            _row('Computer Monitor', 'October 4, 2025', 'Completed'),
            const Divider(color: Colors.black12),
            _row('Chargers', 'April 10, 2025', 'Completed'),
            const Divider(color: Colors.black12),
            _row('Keyboards', 'July 6, 2025', 'Completed'),
            const Divider(color: Colors.black12),
            _row('Old Phone', 'August 7, 2025', 'Completed'),
            const Divider(color: Colors.black12),
            _row('Mouse', 'December 29, 2025', 'Completed'),
          ],
        ),
      ),
    );
  }
}
