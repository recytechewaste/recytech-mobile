import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const route = '/settings';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final theme = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
          children: [
            Text(
              'Appearance',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Choose how RecyTech looks on this device.',
              style: textTheme.bodySmall,
            ),
            SizedBox(height: 16.h),
            Card(
              child: SwitchListTile.adaptive(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                secondary: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    theme.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 21.sp,
                  ),
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(
                  theme.isDarkMode
                      ? 'Charcoal surfaces with mint accents'
                      : 'Light neutral surfaces with emerald accents',
                ),
                value: theme.isDarkMode,
                onChanged: (value) => _setDarkMode(context, value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDarkMode(BuildContext context, bool enabled) async {
    try {
      await context.read<ThemeController>().setDarkMode(enabled);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save the appearance setting.'),
        ),
      );
    }
  }
}
