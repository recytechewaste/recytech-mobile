import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'data/repositories/auth_repository.dart';
import 'services/auth_provider.dart';

import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/auth/forgot_password_screen.dart';
import 'presentation/auth/verify_email_screen.dart';
import 'presentation/collector/shell/collector_home_shell.dart';
import 'presentation/lgu/shell/lgu_home_shell.dart';
import 'presentation/shell/access_denied_screen.dart';
import 'presentation/shell/role_shell.dart';
import 'presentation/shell/user_app_shell.dart';
import 'presentation/settings/settings_screen.dart';

import 'core/theme/recytechtheme.dart';
import 'core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = ThemeController();
  await themeController.load();

  runApp(RecyTechApp(themeController: themeController));
}

class RecyTechApp extends StatelessWidget {
  const RecyTechApp({
    super.key,
    required this.themeController,
  });

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(AuthRepository()),
        ),
        ChangeNotifierProvider<ThemeController>.value(
          value: themeController,
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) {
          return Consumer<ThemeController>(
            builder: (context, theme, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'RecyTech Mobile',
              theme: RecyTechTheme.light(),
              darkTheme: RecyTechTheme.dark(),
              themeMode: theme.themeMode,
              home: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.isLoading) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (auth.user != null) {
                    return RoleShell(userType: auth.user!.role);
                  }

                  return const LoginScreen();
                },
              ),
              routes: {
                LoginScreen.route: (_) => const LoginScreen(),
                RegisterScreen.route: (_) => const RegisterScreen(),
                ForgotPasswordScreen.route: (_) => const ForgotPasswordScreen(),
                VerifyEmailScreen.route: (context) {
                  final email = ModalRoute.of(context)
                          ?.settings
                          .arguments
                          ?.toString() ??
                      context.read<AuthProvider>().pendingVerificationEmail ??
                      '';
                  return VerifyEmailScreen(email: email);
                },
                RoleShell.route: (context) => RoleShell(
                      userType: ModalRoute.of(context)
                              ?.settings
                              .arguments
                              ?.toString() ??
                          context.read<AuthProvider>().role ??
                          '',
                    ),
                CollectorHomeShell.route: (_) => const CollectorHomeShell(),
                LguHomeShell.route: (_) => const LguHomeShell(),
                AccessDeniedScreen.route: (_) => const AccessDeniedScreen(),
                SettingsScreen.route: (_) => const SettingsScreen(),
                UserAppShell.route: (_) => const UserAppShell(),
              },
            ),
          );
        },
      ),
    );
  }
}
