import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/presentation/collector/shell/collector_home_shell.dart';
import 'package:recytecmobproj/presentation/lgu/shell/lgu_home_shell.dart';
import 'package:recytecmobproj/presentation/shell/access_denied_screen.dart';
import 'package:recytecmobproj/services/auth_provider.dart';
import 'package:recytecmobproj/widgets/labeled_textfied.dart';
import 'package:recytecmobproj/presentation/shell/user_app_shell.dart';
import '../../widgets/primary_button.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final success = await context.read<AuthProvider>().login(
          email.text.trim(),
          pass.text,
        );

    if (!mounted) return;

    if (success) {
      final user = context.read<AuthProvider>().currentUser;
      final target = AppRoles.shellTargetFor(user?.role);

      if (target == AppShellTarget.accessDenied) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AccessDeniedScreen(role: user?.role),
          ),
          (route) => false,
        );
        return;
      }

      final route = switch (target) {
        AppShellTarget.household => UserAppShell.route,
        AppShellTarget.lgu => LguHomeShell.route,
        AppShellTarget.collector => CollectorHomeShell.route,
        AppShellTarget.accessDenied => AccessDeniedScreen.route,
      };

      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        (route) => false,
      );
      return;
    }

    final message =
        context.read<AuthProvider>().error ?? 'Login failed. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ❌ NO APPBAR = NO SMALL LOGO / NO TITLE
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          children: [
            SizedBox(height: 24.h),

            // ✅ MAIN LOGO (CENTER)
            Center(
              child: Image.asset(
                'assets/images/recytech_logo.png',
                height: 80.h,
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(height: 16.h),

            Center(
              child: Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
            ),

            SizedBox(height: 6.h),

            Center(
              child: Text(
                'Login to manage your e-waste responsibly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.black54,
                  height: 1.3,
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // ✅ LOGIN CARD
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledTextField(
                    label: 'Email',
                    hintText: 'Enter your email',
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  SizedBox(height: 14.h),
                  LabeledTextField(
                    label: 'Password',
                    hintText: 'Enter your password',
                    controller: pass,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                  ),
                  SizedBox(height: 14.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        ForgotPasswordScreen.route,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  auth.isLoading
                      ? SizedBox(
                          height: 44.h,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        )
                      : PrimaryButton(
                          text: 'Login',
                          width: double.infinity,
                          onPressed: _handleLogin,
                        ),
                ],
              ),
            ),

            SizedBox(height: 20.h),
            Center(
              child: TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          RegisterScreen.route,
                        ),
                child: Text(
                  'Create Household Account',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
