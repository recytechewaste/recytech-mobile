import 'package:flutter/material.dart';

/// Central visual language for the RecyTech mobile application.
///
/// New UI should read colors from [Theme.of] / [ColorScheme]. The adaptive
/// compatibility getters keep older presentation code theme-aware while it is
/// progressively moved away from fixed light-mode colors.
class RecyTechTheme {
  static const _lightPrimary = Color(0xFF08765A);
  static const _lightSecondary = Color(0xFF326B58);
  static const _lightAccent = Color(0xFF2FBF91);
  static const _lightSuccess = Color(0xFF147A52);
  static const _lightWarning = Color(0xFFA76100);
  static const _lightDanger = Color(0xFFB42318);

  static const _darkPrimary = Color(0xFF49D6A7);
  static const _darkSecondary = Color(0xFF8ED6BB);
  static const _darkAccent = Color(0xFF9BE7CC);
  static const _darkSuccess = Color(0xFF63DBA8);
  static const _darkWarning = Color(0xFFFFC66D);
  static const _darkDanger = Color(0xFFFF8A80);

  static const _lightBackground = Color(0xFFF4F7F5);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSubtle = Color(0xFFEDF4F0);
  static const _lightText = Color(0xFF17201C);
  static const _lightMuted = Color(0xFF65736D);
  static const _lightBorder = Color(0xFFD8E2DC);

  static const _darkBackground = Color(0xFF0A0F0D);
  static const _darkSurface = Color(0xFF121916);
  static const _darkSubtle = Color(0xFF19251F);
  static const _darkText = Color(0xFFF0F6F3);
  static const _darkMuted = Color(0xFF9AAEA5);
  static const _darkBorder = Color(0xFF2B3A33);

  static bool _darkMode = false;

  static void setDarkMode(bool value) => _darkMode = value;

  static Color get primary => _darkMode ? _darkPrimary : _lightPrimary;
  static Color get secondary => _darkMode ? _darkSecondary : _lightSecondary;
  static Color get accent => _darkMode ? _darkAccent : _lightAccent;
  static Color get success => _darkMode ? _darkSuccess : _lightSuccess;
  static Color get warning => _darkMode ? _darkWarning : _lightWarning;
  static Color get danger => _darkMode ? _darkDanger : _lightDanger;
  static Color get bg => _darkMode ? _darkBackground : _lightBackground;
  static Color get card => _darkMode ? _darkSurface : _lightSurface;
  static Color get pill => _darkMode ? _darkSubtle : _lightSubtle;
  static Color get textDark => _darkMode ? _darkText : _lightText;
  static Color get textMuted => _darkMode ? _darkMuted : _lightMuted;
  static Color get border => _darkMode ? _darkBorder : _lightBorder;

  static const double screenPadding = 16;
  static const double cardRadius = 12;
  static const double controlRadius = 10;

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? _darkBackground : _lightBackground;
    final surface = isDark ? _darkSurface : _lightSurface;
    final subtle = isDark ? _darkSubtle : _lightSubtle;
    final text = isDark ? _darkText : _lightText;
    final muted = isDark ? _darkMuted : _lightMuted;
    final outline = isDark ? _darkBorder : _lightBorder;
    final schemePrimary = isDark ? _darkPrimary : _lightPrimary;
    final onPrimary = isDark ? const Color(0xFF062A1F) : Colors.white;
    final error = isDark ? const Color(0xFFFFB4AB) : _lightDanger;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: schemePrimary,
      onPrimary: onPrimary,
      primaryContainer:
          isDark ? const Color(0xFF0B513D) : const Color(0xFFD5F4E7),
      onPrimaryContainer:
          isDark ? const Color(0xFFC5F5E3) : const Color(0xFF073B2E),
      secondary: isDark ? _darkSecondary : _lightSecondary,
      onSecondary: isDark ? const Color(0xFF0B3528) : Colors.white,
      secondaryContainer: subtle,
      onSecondaryContainer: text,
      tertiary: isDark ? _darkAccent : _lightAccent,
      onTertiary: isDark ? const Color(0xFF07382B) : const Color(0xFF062D22),
      tertiaryContainer:
          isDark ? const Color(0xFF174C3B) : const Color(0xFFD8F7EB),
      onTertiaryContainer: text,
      error: error,
      onError: isDark ? const Color(0xFF690005) : Colors.white,
      errorContainer:
          isDark ? const Color(0xFF4A1716) : const Color(0xFFFFE8E5),
      onErrorContainer:
          isDark ? const Color(0xFFFFDAD6) : const Color(0xFF7A271A),
      surface: surface,
      onSurface: text,
      surfaceContainerLowest: isDark ? const Color(0xFF080C0A) : Colors.white,
      surfaceContainerLow:
          isDark ? const Color(0xFF0F1512) : const Color(0xFFF8FAF9),
      surfaceContainer: subtle,
      surfaceContainerHigh:
          isDark ? const Color(0xFF1F2B25) : const Color(0xFFE8EFEB),
      surfaceContainerHighest:
          isDark ? const Color(0xFF26342D) : const Color(0xFFDDE6E1),
      onSurfaceVariant: muted,
      outline: isDark ? const Color(0xFF53675D) : const Color(0xFF718079),
      outlineVariant: outline,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface:
          isDark ? const Color(0xFFE2EAE6) : const Color(0xFF26302B),
      onInverseSurface:
          isDark ? const Color(0xFF1C2521) : const Color(0xFFF1F6F3),
      inversePrimary: isDark ? _lightPrimary : const Color(0xFF54DDB0),
      surfaceTint: Colors.transparent,
    );

    final baseTextTheme = (isDark ? ThemeData.dark() : ThemeData.light())
        .textTheme
        .apply(bodyColor: text, displayColor: text)
        .copyWith(
          headlineSmall: TextStyle(
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: text,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: text,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: text,
          ),
          bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: text),
          bodySmall: TextStyle(fontSize: 12, height: 1.35, color: muted),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: BorderSide(color: outline),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: 'Roboto',
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        foregroundColor: text,
        iconTheme: IconThemeData(color: text, size: 22),
        actionsIconTheme: IconThemeData(color: schemePrimary, size: 22),
        titleTextStyle: TextStyle(
          fontSize: 18,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: text,
        ),
        shape: Border(bottom: BorderSide(color: outline, width: 0.7)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: schemePrimary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: schemePrimary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: schemePrimary,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: outline),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: schemePrimary,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF0F1512) : _lightSurface,
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        floatingLabelStyle: TextStyle(
          color: schemePrimary,
          fontWeight: FontWeight.w700,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: outline.withValues(alpha: 0.6)),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: schemePrimary, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: error, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: subtle,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: outline),
        labelStyle: TextStyle(color: text, fontWeight: FontWeight.w700),
        secondaryLabelStyle:
            TextStyle(color: schemePrimary, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 0.8),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: schemePrimary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF25322C) : const Color(0xFF26332D),
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor:
            isDark ? const Color(0xFF80E7C2) : const Color(0xFFB7F2DC),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: outline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? schemePrimary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: schemePrimary,
        unselectedItemColor: muted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color:
                states.contains(WidgetState.selected) ? schemePrimary : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color:
                states.contains(WidgetState.selected) ? schemePrimary : muted,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
