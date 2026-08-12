import 'package:flutter/material.dart';

import '../../../core/theme/recytechtheme.dart';
import '../dashboard/lgu_dashboard_screen.dart';
import '../bins/assigned_bins_screen.dart';
import '../requests/collection_request_tracking_screen.dart';
import '../profile/lgu_profile_screen.dart';

class LguHomeShell extends StatefulWidget {
  static const route = '/lgu-app';

  const LguHomeShell({super.key});

  @override
  State<LguHomeShell> createState() => _LguHomeShellState();
}

class _LguHomeShellState extends State<LguHomeShell> {
  int index = 0;

  final screens = const [
    LguDashboardScreen(),
    AssignedBinsScreen(),
    CollectionRequestTrackingScreen(),
    LguProfileScreen(),
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
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: _NavPill(icon: Icons.dashboard_outlined),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.delete_outline),
              activeIcon: _NavPill(icon: Icons.delete_outline),
              label: 'Bins',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: _NavPill(icon: Icons.local_shipping_outlined),
              label: 'Requests',
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
  const _NavPill({required this.icon});

  final IconData icon;

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
