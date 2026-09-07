import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recytecmobproj/core/storage/secure_storage.dart';
import 'package:recytecmobproj/core/theme/recytechtheme.dart';
import 'package:recytecmobproj/core/theme/theme_controller.dart';
import 'package:recytecmobproj/presentation/settings/settings_screen.dart';

void main() {
  tearDown(() => RecyTechTheme.setDarkMode(false));

  test('loads and persists the device appearance preference', () async {
    final storage = _FakeStorage()..darkMode = true;
    final controller = ThemeController(storage: storage);

    await controller.load();
    expect(controller.themeMode, ThemeMode.dark);

    await controller.setDarkMode(false);
    expect(controller.themeMode, ThemeMode.light);
    expect(storage.darkMode, isFalse);
  });

  testWidgets('Dark Mode setting updates the whole app immediately',
      (tester) async {
    final storage = _FakeStorage();
    final controller = ThemeController(storage: storage);
    await controller.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeController>.value(
        value: controller,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => Consumer<ThemeController>(
            builder: (context, theme, _) => MaterialApp(
              theme: RecyTechTheme.light(),
              darkTheme: RecyTechTheme.dark(),
              themeMode: theme.themeMode,
              home: const SettingsScreen(),
            ),
          ),
        ),
      ),
    );

    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.light,
    );

    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();

    expect(controller.isDarkMode, isTrue);
    expect(storage.darkMode, isTrue);
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
  });
}

class _FakeStorage extends SecureStorage {
  bool? darkMode;

  @override
  Future<bool?> readDarkMode() async => darkMode;

  @override
  Future<void> saveDarkMode(bool enabled) async => darkMode = enabled;
}
