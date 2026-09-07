import 'package:flutter/material.dart';

import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/presentation/collector/assigned/collector_assigned_screen.dart';
import 'package:recytecmobproj/presentation/collector/history/collector_history_screen.dart';
import 'package:recytecmobproj/presentation/collector/profile/collector_profile_screen.dart';
import 'package:recytecmobproj/presentation/notifications/notification_center_screen.dart';
import 'package:recytecmobproj/widgets/app_bottom_navigation.dart';

class CollectorHomeShell extends StatefulWidget {
  static const route = '/collector-app';

  const CollectorHomeShell({super.key});

  @override
  State<CollectorHomeShell> createState() => _CollectorHomeShellState();
}

class _CollectorHomeShellState extends State<CollectorHomeShell> {
  int index = 0;

  final List<Widget> screens = const [
    CollectorAssignedScreen(),
    CollectorHistoryScreen(),
    NotificationCenterScreen(role: UserRole.collector),
    CollectorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          AppNavigationItem(
            icon: Icons.assignment_outlined,
            label: 'Assigned Requests',
          ),
          AppNavigationItem(icon: Icons.history, label: 'History'),
          AppNavigationItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
          ),
          AppNavigationItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }
}
