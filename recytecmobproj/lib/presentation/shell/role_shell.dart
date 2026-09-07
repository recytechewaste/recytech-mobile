import 'package:flutter/material.dart';

import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/presentation/collector/shell/collector_home_shell.dart';
import 'package:recytecmobproj/presentation/lgu/shell/lgu_home_shell.dart';
import 'package:recytecmobproj/presentation/shell/access_denied_screen.dart';
import 'package:recytecmobproj/presentation/shell/user_app_shell.dart';

class RoleShell extends StatelessWidget {
  static const route = '/role';

  final String userType;

  const RoleShell({
    super.key,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    switch (AppRoles.shellTargetFor(userType)) {
      case AppShellTarget.household:
        return const UserAppShell();
      case AppShellTarget.partnerOrg:
        return const LguHomeShell();
      case AppShellTarget.collector:
        return const CollectorHomeShell();
      case AppShellTarget.accessDenied:
        return AccessDeniedScreen(role: userType);
    }
  }
}
