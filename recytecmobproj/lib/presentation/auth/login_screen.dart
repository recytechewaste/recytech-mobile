import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/presentation/collector/shell/collector_home_shell.dart';
import 'package:recytecmobproj/presentation/lgu/shell/lgu_home_shell.dart';
import 'package:recytecmobproj/presentation/shell/access_denied_screen.dart';
import 'package:recytecmobproj/presentation/shell/user_app_shell.dart';
import 'package:recytecmobproj/services/auth_provider.dart';
import 'package:recytecmobproj/widgets/labeled_textfied.dart';
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
  bool _passwordVisible = false;

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
      _routeAuthenticatedUser();
      return;
    }

    final message =
        context.read<AuthProvider>().error ?? 'Login failed. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _routeAuthenticatedUser() {
    final user = context.read<AuthProvider>().currentUser;
    final target = AppRoles.shellTargetFor(user?.role);

    if (target == AppShellTarget.accessDenied) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AccessDeniedScreen(role: user?.role),
        ),
        (_) => false,
      );
      return;
    }

    final route = switch (target) {
      AppShellTarget.household => UserAppShell.route,
      AppShellTarget.partnerOrg => LguHomeShell.route,
      AppShellTarget.collector => CollectorHomeShell.route,
      AppShellTarget.accessDenied => AccessDeniedScreen.route,
    };

    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 285.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? const [Color(0xFF07110D), Color(0xFF0B513D)]
                    : const [Color(0xFF064E3B), Color(0xFF08765A)],
              ),
            ),
          ),
          SafeArea(
            child: AutofillGroup(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/recytech_logo.png',
                      height: 92.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'RecyTech',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(18.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            'Sign in to access RecyTech.',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 20.h),
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
                            obscureText: !_passwordVisible,
                            enableSuggestions: false,
                            autocorrect: false,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            suffixIcon: IconButton(
                              tooltip: _passwordVisible
                                  ? 'Hide password'
                                  : 'Show password',
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                ForgotPasswordScreen.route,
                              ),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          auth.isLoading
                              ? SizedBox(
                                  height: 48.h,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : PrimaryButton(
                                  text: 'Login',
                                  width: double.infinity,
                                  onPressed: _handleLogin,
                                ),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'New to RecyTech?',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => Navigator.pushNamed(
                                          context,
                                          RegisterScreen.route,
                                        ),
                                child: const Text('Register'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
