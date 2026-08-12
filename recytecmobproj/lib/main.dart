import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'data/repositories/auth_repository.dart';
import 'services/auth_provider.dart';

import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/auth/forgot_password_screen.dart';
import 'presentation/collector/shell/collector_home_shell.dart';
import 'presentation/lgu/shell/lgu_home_shell.dart';
import 'presentation/shell/access_denied_screen.dart';
import 'presentation/shell/user_app_shell.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/recytechtheme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const RecyTechApp());
}

class RecyTechApp extends StatelessWidget {
  const RecyTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(AuthRepository()),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'RecyTech Mobile',
            theme: RecyTechTheme.light(),
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (auth.user != null) {
                  switch (AppRoles.shellTargetFor(auth.user!.role)) {
                    case AppShellTarget.household:
                      return const UserAppShell();
                    case AppShellTarget.lgu:
                      return const LguHomeShell();
                    case AppShellTarget.collector:
                      return const CollectorHomeShell();
                    case AppShellTarget.accessDenied:
                      return AccessDeniedScreen(role: auth.user!.role);
                  }
                }

                return const LoginScreen();
              },
            ),
            routes: {
              LoginScreen.route: (_) => const LoginScreen(),
              RegisterScreen.route: (_) => const RegisterScreen(),
              ForgotPasswordScreen.route: (_) => const ForgotPasswordScreen(),
              CollectorHomeShell.route: (_) => const CollectorHomeShell(),
              LguHomeShell.route: (_) => const LguHomeShell(),
              AccessDeniedScreen.route: (_) => const AccessDeniedScreen(),
              // Legacy household shell kept for comparison/debug during migration.
              UserAppShell.route: (_) => const UserAppShell(),
            },
          );
        },
      ),
    );
  }
}
