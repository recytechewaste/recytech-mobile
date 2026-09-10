import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  static const route = '/verify-email';

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final pin = _pin.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      _showMessage('Enter the 6-digit PIN sent to your email.');
      return;
    }

    final result = await context.read<AuthProvider>().verifyEmail(
          email: widget.email,
          pin: pin,
        );

    if (!mounted) return;
    if (result == null) {
      _showMessage(
        context.read<AuthProvider>().error ??
            'Email verification failed. Please try again.',
      );
      return;
    }

    _showMessage(result.message);
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.route,
      (route) => false,
    );
  }

  Future<void> _resend() async {
    final message =
        await context.read<AuthProvider>().resendVerification(widget.email);
    if (!mounted) return;
    _showMessage(
      message ??
          context.read<AuthProvider>().error ??
          'Could not resend verification PIN. Please try again.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 24.h),
          children: [
            SizedBox(height: 20.h),
            Icon(
              Icons.mark_email_read_outlined,
              size: 54.sp,
              color: scheme.primary,
            ),
            SizedBox(height: 18.h),
            Text(
              'Enter Verification PIN',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.70),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 24.h),
            TextField(
              controller: _pin,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Verification PIN',
                hintText: 'Enter 6-digit PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => auth.isLoading ? null : _verify(),
            ),
            SizedBox(height: 18.h),
            auth.isLoading
                ? SizedBox(
                    height: 44.h,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : PrimaryButton(
                    text: 'Verify Email',
                    width: double.infinity,
                    onPressed: _verify,
                  ),
            SizedBox(height: 10.h),
            Center(
              child: TextButton(
                onPressed: auth.isLoading ? null : _resend,
                child: const Text('Resend PIN'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          LoginScreen.route,
                          (route) => false,
                        ),
                child: const Text('Back to Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
