import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/recytechtheme.dart';
import '../../core/utils/helpers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/labeled_textfied.dart';
import '../../widgets/primary_button.dart';

enum _ResetStep {
  email,
  pin,
  password,
  success,
}

class ForgotPasswordScreen extends StatefulWidget {
  static const route = '/forgot';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pin = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  _ResetStep _step = _ResetStep.email;
  bool _submitting = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _resetToken;
  String? _statusMessage;

  @override
  void dispose() {
    _email.dispose();
    _pin.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _requestPin() async {
    final email = _email.text.trim();
    final error = _validateEmail(email);
    if (error != null) {
      _showMessage(error);
      return;
    }

    await _runRequest(() async {
      final message = await _authRepository.forgotPassword(email);
      setState(() {
        _statusMessage = message;
        _step = _ResetStep.pin;
      });
    });
  }

  Future<void> _verifyPin() async {
    final pin = _pin.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      _showMessage('Enter the 6-digit PIN sent to your email.');
      return;
    }

    await _runRequest(() async {
      final token = await _authRepository.verifyResetPin(
        email: _email.text.trim(),
        pin: pin,
      );
      setState(() {
        _resetToken = token;
        _statusMessage = 'PIN verified. Create your new password.';
        _step = _ResetStep.password;
      });
    });
  }

  Future<void> _resetPassword() async {
    final password = _newPassword.text;
    final confirm = _confirmPassword.text;
    final token = _resetToken;

    final error = _validatePassword(password, confirm);
    if (error != null) {
      _showMessage(error);
      return;
    }

    if (token == null || token.isEmpty) {
      _showMessage('Please verify your PIN again before resetting password.');
      setState(() => _step = _ResetStep.pin);
      return;
    }

    await _runRequest(() async {
      final message = await _authRepository.resetPassword(
        email: _email.text.trim(),
        newPassword: password,
        confirmPassword: confirm,
        resetToken: token,
      );
      setState(() {
        _statusMessage = message;
        _step = _ResetStep.success;
      });
    });
  }

  Future<void> _runRequest(Future<void> Function() request) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      await request();
    } catch (e) {
      _showMessage(_messageForError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Enter your email address.';
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    return valid ? null : 'Enter a valid email address.';
  }

  String? _validatePassword(String password, String confirm) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (password != confirm) return 'Passwords do not match.';
    return null;
  }

  String _messageForError(Object error) {
    return userFacingError(
      error,
      fallback: 'Unable to reset the password. Please try again.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecyTechTheme.bg,
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 18.h),
          children: [
            _header(),
            SizedBox(height: 18.h),
            _progress(),
            SizedBox(height: 18.h),
            if (_statusMessage != null) ...[
              _statusBanner(_statusMessage!),
              SizedBox(height: 14.h),
            ],
            _currentStep(),
            SizedBox(height: 12.h),
            Center(
              child: TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                child: const Text('Back to login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Container(
          width: 58.w,
          height: 58.w,
          decoration: BoxDecoration(
            color: RecyTechTheme.pill,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_reset,
            color: RecyTechTheme.primary,
            size: 30.sp,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: RecyTechTheme.textDark,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          _subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            height: 1.35,
            color: RecyTechTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _progress() {
    final activeIndex = _step.index.clamp(0, 2);
    final labels = ['Email', 'PIN', 'Password'];

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: i <= activeIndex
                        ? RecyTechTheme.primary
                        : RecyTechTheme.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: RecyTechTheme.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i <= activeIndex
                          ? Colors.white
                          : RecyTechTheme.textMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: RecyTechTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (i != labels.length - 1)
            Container(
              width: 28.w,
              height: 2,
              color: i < activeIndex
                  ? RecyTechTheme.primary
                  : RecyTechTheme.border,
            ),
        ],
      ],
    );
  }

  Widget _statusBanner(String message) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11.sp,
          color: RecyTechTheme.textDark,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _currentStep() {
    switch (_step) {
      case _ResetStep.email:
        return _emailStep();
      case _ResetStep.pin:
        return _pinStep();
      case _ResetStep.password:
        return _passwordStep();
      case _ResetStep.success:
        return _successStep();
    }
  }

  Widget _emailStep() {
    return _panel(
      children: [
        LabeledTextField(
          label: 'Email Address',
          hintText: 'Enter your email address',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
        ),
        SizedBox(height: 16.h),
        _submitButton('Send PIN', _requestPin),
      ],
    );
  }

  Widget _pinStep() {
    return _panel(
      children: [
        TextField(
          controller: _pin,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Verification PIN',
            hintText: 'Enter 6-digit PIN',
            counterText: '',
          ),
        ),
        SizedBox(height: 16.h),
        _submitButton('Verify PIN', _verifyPin),
        SizedBox(height: 8.h),
        Center(
          child: TextButton(
            onPressed: _submitting ? null : _requestPin,
            child: const Text('Resend PIN'),
          ),
        ),
      ],
    );
  }

  Widget _passwordStep() {
    return _panel(
      children: [
        LabeledTextField(
          label: 'New Password',
          hintText: 'Enter new password',
          controller: _newPassword,
          obscureText: !_newPasswordVisible,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          suffixIcon: IconButton(
            tooltip: _newPasswordVisible ? 'Hide password' : 'Show password',
            onPressed: () => setState(
              () => _newPasswordVisible = !_newPasswordVisible,
            ),
            icon: Icon(
              _newPasswordVisible ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        LabeledTextField(
          label: 'Confirm Password',
          hintText: 'Re-enter new password',
          controller: _confirmPassword,
          obscureText: !_confirmPasswordVisible,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          suffixIcon: IconButton(
            tooltip: _confirmPasswordVisible
                ? 'Hide confirm password'
                : 'Show confirm password',
            onPressed: () => setState(
              () => _confirmPasswordVisible = !_confirmPasswordVisible,
            ),
            icon: Icon(
              _confirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _submitButton('Reset Password', _resetPassword),
      ],
    );
  }

  Widget _successStep() {
    return _panel(
      children: [
        Icon(
          Icons.check_circle_outline,
          color: RecyTechTheme.primary,
          size: 44.sp,
        ),
        SizedBox(height: 10.h),
        Text(
          'Password Reset Complete',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            color: RecyTechTheme.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 14.h),
        PrimaryButton(
          text: 'Return to Login',
          onPressed: _submitting
              ? null
              : () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (_) => false,
                  ),
        ),
      ],
    );
  }

  Widget _panel({required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: RecyTechTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RecyTechTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _submitButton(String label, Future<void> Function() onPressed) {
    return _submitting
        ? SizedBox(
            height: 48.h,
            child: const Center(child: CircularProgressIndicator()),
          )
        : PrimaryButton(
            text: label,
            onPressed: onPressed,
          );
  }

  String get _subtitle {
    switch (_step) {
      case _ResetStep.email:
        return 'Enter your account email to receive a reset PIN.';
      case _ResetStep.pin:
        return 'Enter the verification PIN sent by the backend email service.';
      case _ResetStep.password:
        return 'Create a new password with at least 6 characters.';
      case _ResetStep.success:
        return 'You can now sign in using your new password.';
    }
  }
}
