import 'package:flutter/material.dart';

import 'package:recytecmobproj/presentation/collector/shell/collector_home_shell.dart';
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
    if (userType.toLowerCase() == 'collector') {
      return const CollectorHomeShell();
    }
    return UserAppShell();
  }
}
