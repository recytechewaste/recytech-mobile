import 'package:flutter/material.dart';

import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/presentation/collector/home/collector_home_screen.dart';
import 'package:recytecmobproj/presentation/collector/assigned/collector_assigned_screen.dart';
import 'package:recytecmobproj/presentation/collector/history/collector_history_screen.dart';
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
    CollectorHistoryScreen(),
    CollectorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(top: BorderSide(color: RecyTechTheme.border)),
          boxShadow: [
            BoxShadow(
              color: RecyTechTheme.primary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: RecyTechTheme.card,
          selectedItemColor: RecyTechTheme.primary,
          unselectedItemColor: RecyTechTheme.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: _NavPill(icon: Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: _NavPill(icon: Icons.assignment_outlined),
              label: 'Assigned',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              activeIcon: _NavPill(icon: Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: _NavPill(icon: Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final IconData icon;

  const _NavPill({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: RecyTechTheme.pill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(icon, color: RecyTechTheme.primary),
    );
  }
}
