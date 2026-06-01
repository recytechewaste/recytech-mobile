import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:recytecmobproj/widgets/labeled_textfied.dart';
import '../../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const route = '/forgot';
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  final newPass = TextEditingController();
  final confirm = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    newPass.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My App')),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 22.w),
        children: [
          SizedBox(height: 34.h),
          Center(
            child: Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(height: 24.h),
          LabeledTextField(
            label: 'Email Address*',
            hintText: 'Enter your email address',
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          SizedBox(height: 14.h),
          LabeledTextField(
            label: 'Create a new password*',
            hintText: 'Enter new password',
            controller: newPass,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
          ),
          SizedBox(height: 14.h),
          LabeledTextField(
            label: 'Confirm Password*',
            hintText: 'Re-enter new password',
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
            child: PrimaryButton(
              text: 'Reset Password',
              width: 260.w,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SizedBox(height: 10.h),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back to login page',
                  style: TextStyle(fontSize: 12.sp, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}
