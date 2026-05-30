import 'package:flutter/material.dart';

import 'package:recytecmobproj/presentation/collector/home/collector_home_screen.dart';
import 'package:recytecmobproj/presentation/collector/assigned/collector_assigned_screen.dart';
import 'package:recytecmobproj/presentation/collector/profile/collector_profile_screen.dart';

class CollectorHomeShell extends StatefulWidget {
  static const route = '/collector-app';

  const CollectorHomeShell({super.key});

  @override
  State<CollectorHomeShell> createState() => _CollectorHomeShellState();
}

class _CollectorHomeShellState extends State<CollectorHomeShell> {
  int index = 0;

  final List<Widget> screens = const [
    CollectorHomeScreen(),
    CollectorAssignedScreen(),
    CollectorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Assigned',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
