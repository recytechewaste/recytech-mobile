import 'package:flutter/material.dart';

import '../../../widgets/app_bottom_navigation.dart';
import '../dashboard/lgu_dashboard_screen.dart';
import '../bins/assigned_bins_screen.dart';
import '../requests/collection_request_tracking_screen.dart';
import '../rewards/partner_rewards_screen.dart';
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
    PartnerRewardsScreen(),
    LguProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          AppNavigationItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
          AppNavigationItem(icon: Icons.delete_outline, label: 'Bins'),
          AppNavigationItem(
              icon: Icons.local_shipping_outlined, label: 'Requests'),
          AppNavigationItem(icon: Icons.redeem_outlined, label: 'Rewards'),
          AppNavigationItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }
}
