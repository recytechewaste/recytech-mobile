import 'package:flutter/material.dart';

import '../user/dashboard/dashboard_screen.dart';
import '../user/ewaste_service/ai_capture_screen.dart';
import '../user/rewards/rewards_screen.dart';
import '../user/history/history_screen.dart';
import '../user/profile/profile_screen.dart';

class UserAppShell extends StatefulWidget {
  static const route = '/user-app';
  const UserAppShell({super.key});

  @override
  State<UserAppShell> createState() => _UserAppShellState();
}

class _UserAppShellState extends State<UserAppShell> {
  int index = 0;

  // 🔥 MATCHES: Home / Submit / Rewards / History / Profile
  final screens = const [
    UserDashboardScreen(), // Home
    AICaptureScreen(), // Submit
    RewardsScreen(), // Rewards
    HistoryScreen(), // History
    ProfileScreen(), // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],

      // 🔥 MATCHES Figma bottom bar exactly
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEFEFEF),
          border: Border(
            top: BorderSide(color: Colors.black12, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFEFEFEF),
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black45,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedIconTheme: const IconThemeData(size: 22),
          unselectedIconTheme: const IconThemeData(size: 22),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.send_outlined),
              label: 'Submit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              label: 'Rewards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
