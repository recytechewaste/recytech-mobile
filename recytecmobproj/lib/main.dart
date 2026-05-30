import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'data/repositories/auth_repository.dart';
import 'services/auth_provider.dart';

import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/auth/forgot_password_screen.dart';
import 'presentation/collector/shell/collector_home_shell.dart';
import 'presentation/shell/user_app_shell.dart';

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
                if (auth.user != null) {
                  if (auth.user!.role.toLowerCase() == 'collector') {
                    return const CollectorHomeShell();
                  }

                  return UserAppShell();
                }

                return const LoginScreen();
              },
            ),
            routes: {
              LoginScreen.route: (_) => const LoginScreen(),
              RegisterScreen.route: (_) => const RegisterScreen(),
              ForgotPasswordScreen.route: (_) => const ForgotPasswordScreen(),
              CollectorHomeShell.route: (_) => const CollectorHomeShell(),
              UserAppShell.route: (_) => UserAppShell(),
            },
          );
        },
      ),
    );
  }
}
