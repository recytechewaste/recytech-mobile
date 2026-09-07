import 'package:flutter/material.dart';

import '../../widgets/app_bottom_navigation.dart';
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
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          AppNavigationItem(icon: Icons.home_outlined, label: 'Home'),
          AppNavigationItem(icon: Icons.location_on_outlined, label: 'Locator'),
          AppNavigationItem(
              icon: Icons.emoji_events_outlined, label: 'Rewards'),
          AppNavigationItem(icon: Icons.history, label: 'History'),
          AppNavigationItem(icon: Icons.menu_book_outlined, label: 'Education'),
          AppNavigationItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }
}
