import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:recytecmobproj/core/constants/app_constants.dart';
import 'package:recytecmobproj/services/auth_provider.dart';
import 'package:recytecmobproj/widgets/labeled_textfied.dart';

import '../../widgets/primary_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const route = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final organizationName = TextEditingController();
  final contactNumber = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();

  String role = AppRoles.household;
  String vehicleType = 'Not Assigned';
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    name.dispose();
    organizationName.dispose();
    contactNumber.dispose();
    email.dispose();
    pass.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final message = _validationMessage();
    if (message != null) {
      _showMessage(message);
      return;
    }

    final result = await context.read<AuthProvider>().register(
          email.text.trim(),
          pass.text,
          fullName: name.text.trim(),
          role: role,
          organizationName: organizationName.text.trim(),
          contactPerson: role == AppRoles.partnerOrg ? name.text.trim() : null,
          contactNumber: contactNumber.text.trim(),
          phone: role == AppRoles.collector ? contactNumber.text.trim() : null,
          vehicleType: role == AppRoles.collector ? vehicleType : null,
        );

    if (!mounted) return;

    if (result != null) {
      _showMessage(result.message);
      Navigator.pushReplacementNamed(context, LoginScreen.route);
      return;
    }

    _showMessage(
      context.read<AuthProvider>().error ??
          'Registration failed. Please try again.',
    );
  }

  String? _validationMessage() {
    if (email.text.trim().isEmpty || pass.text.isEmpty) {
      return 'Email and password are required.';
    }
    if (pass.text.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (pass.text != confirm.text) {
      return 'Passwords do not match.';
    }
    if (role == AppRoles.partnerOrg && organizationName.text.trim().isEmpty) {
      return 'Organization name is required.';
    }
    if (role == AppRoles.collector && contactNumber.text.trim().isEmpty) {
      return 'Contact number is required.';
    }
    return null;
  }

  void _showMessage(String message) {
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
              'Choose the account type that matches your role.',
              style: tt.bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.70)),
            ),
          ),
          SizedBox(height: 22.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Account Type',
              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(height: 8.h),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: AppRoles.household,
                label: FittedBox(child: Text('Registered User')),
              ),
              ButtonSegment(
                value: AppRoles.partnerOrg,
                label: FittedBox(child: Text('Partner Organization')),
              ),
              ButtonSegment(
                  value: AppRoles.collector, label: Text('Collector')),
            ],
            selected: {role},
            showSelectedIcon: false,
            onSelectionChanged: auth.isLoading
                ? null
                : (selection) => setState(() => role = selection.first),
          ),
          SizedBox(height: 18.h),
          if (role == AppRoles.partnerOrg) ...[
            LabeledTextField(
              label: 'Organization Name',
              hintText: 'Enter organization name',
              controller: organizationName,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 14.h),
          ],
          LabeledTextField(
            label: role == AppRoles.partnerOrg ? 'Contact Person' : 'Full Name',
            hintText: role == AppRoles.partnerOrg
                ? 'Enter contact person'
                : 'Enter your full name',
            controller: name,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),
          if (role != AppRoles.household) ...[
            SizedBox(height: 14.h),
            LabeledTextField(
              label: 'Contact Number',
              hintText: 'Enter phone number',
              controller: contactNumber,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
          ],
          if (role == AppRoles.collector) ...[
            SizedBox(height: 14.h),
            DropdownButtonFormField<String>(
              initialValue: vehicleType,
              decoration: const InputDecoration(
                labelText: 'Vehicle Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Not Assigned',
                  child: Text('Not Assigned'),
                ),
                DropdownMenuItem(value: 'E-Trike', child: Text('E-Trike')),
                DropdownMenuItem(value: 'Truck', child: Text('Truck')),
                DropdownMenuItem(value: 'Bike', child: Text('Bike')),
              ],
              onChanged: auth.isLoading
                  ? null
                  : (value) =>
                      setState(() => vehicleType = value ?? 'Not Assigned'),
            ),
          ],
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
            obscureText: !_passwordVisible,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            suffixIcon: IconButton(
              tooltip: _passwordVisible ? 'Hide password' : 'Show password',
              icon: Icon(
                _passwordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _passwordVisible = !_passwordVisible);
              },
            ),
          ),
          SizedBox(height: 14.h),
          LabeledTextField(
            label: 'Confirm Password',
            hintText: 'Re-enter your password',
            controller: confirm,
            obscureText: !_confirmPasswordVisible,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            suffixIcon: IconButton(
              tooltip: _confirmPasswordVisible
                  ? 'Hide confirm password'
                  : 'Show confirm password',
              icon: Icon(
                _confirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(
                  () => _confirmPasswordVisible = !_confirmPasswordVisible,
                );
              },
            ),
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
                'Already have an account? Login',
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
