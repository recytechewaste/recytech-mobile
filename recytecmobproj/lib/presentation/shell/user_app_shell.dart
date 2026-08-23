import 'package:flutter/material.dart';

import '../../core/theme/recytechtheme.dart';
import '../user/bins/bin_locator_screen.dart';
import '../user/dashboard/dashboard_screen.dart';
import '../user/education/education_content_screen.dart';
import '../user/history/history_screen.dart';
import '../user/profile/profile_screen.dart';
import '../user/rewards/rewards_screen.dart';

class UserAppShell extends StatefulWidget {
  static const route = '/user-app';
  const UserAppShell({super.key});

  @override
  State<UserAppShell> createState() => _UserAppShellState();
}

class _UserAppShellState extends State<UserAppShell> {
  int index = 0;

  final screens = const [
    UserDashboardScreen(),
    BinLocatorScreen(),
    RewardsScreen(),
    HistoryScreen(),
    EducationContentScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: RecyTechTheme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: RecyTechTheme.border),
          ),
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
          selectedIconTheme: const IconThemeData(size: 22),
          unselectedIconTheme: const IconThemeData(size: 22),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: _NavPill(icon: Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: _NavPill(icon: Icons.location_on_outlined),
              label: 'Locator',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: _NavPill(icon: Icons.emoji_events_outlined),
              label: 'Rewards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              activeIcon: _NavPill(icon: Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: _NavPill(icon: Icons.menu_book_outlined),
              label: 'Education',
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
