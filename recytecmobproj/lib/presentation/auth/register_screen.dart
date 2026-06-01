import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:recytecmobproj/presentation/shell/user_app_shell.dart';
import 'package:recytecmobproj/services/auth_provider.dart';
import 'package:recytecmobproj/widgets/labeled_textfied.dart';

import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  static const route = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    pass.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (pass.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    final success = await context.read<AuthProvider>().register(
          email.text.trim(),
          pass.text,
          fullName: name.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        UserAppShell.route,
        (route) => false,
      );
      return;
    }

    final message = context.read<AuthProvider>().error ??
        'Registration failed. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('RecyTech')),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
        children: [
          SizedBox(height: 10.h),
          Center(
            child: Text(
              'Create Account',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(height: 6.h),
          Center(
            child: Text(
              'Join RecyTech and help reduce e-waste.',
              style: tt.bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.70)),
            ),
          ),
          SizedBox(height: 22.h),
          LabeledTextField(
            label: 'Full Name',
            hintText: 'Enter your full name',
            controller: name,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),
          SizedBox(height: 14.h),
          LabeledTextField(
            label: 'Email',
            hintText: 'Enter your email address',
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          SizedBox(height: 14.h),
          LabeledTextField(
            label: 'Password',
            hintText: 'Create a password',
            controller: pass,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
          ),
          SizedBox(height: 14.h),
          LabeledTextField(
            label: 'Confirm Password',
            hintText: 'Re-enter your password',
            controller: confirm,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
          ),
          SizedBox(height: 18.h),
          Center(
            child: auth.isLoading
                ? SizedBox(
                    width: 260.w,
                    height: 44.h,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : PrimaryButton(
                    text: 'Register',
                    width: 260.w,
                    onPressed: _handleRegister,
                  ),
          ),
          SizedBox(height: 10.h),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Already have an Account? Login',
                style: tt.bodySmall?.copyWith(
                  fontSize: 12.sp,
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
