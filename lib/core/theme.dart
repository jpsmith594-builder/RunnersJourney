import 'package:flutter/material.dart';

/// The app's look: deep purple with electric green, cyan and magenta accents,
/// white borders and bold white text on purple.
class AppTheme {
  static const Color purple = Color(0xFF37003C);
  static const Color purpleMid = Color(0xFF6B1B9A);
  static const Color green = Color(0xFF00FF85);
  static const Color navy = Color(0xFF0A3FA8); // FPL-style dark blue
  static const Color navyLight = Color(0xFF1D5BD6);
  static const Color cyan = Color(0xFF04F5FF);
  static const Color magenta = Color(0xFFE90052);

  /// Soft grey canvas the white cards sit on (Samsung Health style).
  /// A fresh green for finished races: bright on dark, deeper on light.
  static Color runGreen(Brightness b) => b == Brightness.dark
      ? const Color(0xFF4ADE80)
      : const Color(0xFF16A34A);

  static const Color canvasLight = Color(0xFFE7E1F4);
  static const Color canvasDark = Color(0xFF0B0B10);
  static const Color cardDark = Color(0xFF1C1C24);

  static ThemeData light() => _build(
        ColorScheme.fromSeed(
          seedColor: purpleMid,
          brightness: Brightness.light,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        ).copyWith(
          primary: purple,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFE9DDF5),
          onPrimaryContainer: purple,
          secondary: const Color(0xFF0A8CFF),
          onSecondary: Colors.white,
          tertiary: magenta,
          onTertiary: Colors.white,
          surface: Colors.white,
        ),
        accent: navy,
        onAccent: Colors.white,
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: purpleMid,
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        ).copyWith(
          primary: const Color(0xFFD9B8FF),
          onPrimary: purple,
          primaryContainer: const Color(0xFF52125A),
          onPrimaryContainer: Colors.white,
          secondary: const Color(0xFF5CB8FF),
          onSecondary: const Color(0xFF00213D),
          tertiary: const Color(0xFFFF4D8D),
          onTertiary: Colors.white,
          surface: cardDark,
          onSurface: Colors.white,
        ),
        accent: navyLight,
        onAccent: Colors.white,
      );

  static ThemeData _build(ColorScheme scheme,
      {required Color accent, required Color onAccent}) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final t = base.textTheme;
    final dark = scheme.brightness == Brightness.dark;
    final canvas = dark ? canvasDark : canvasLight;
    final fg = dark ? Colors.white : const Color(0xFF14141A);
    final muted = dark ? Colors.white60 : const Color(0xFF6B6F7B);
    final header = dark ? cardDark : const Color(0xFF1F1F27); // snack bars
    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      textTheme: t.apply(bodyColor: fg, displayColor: fg).copyWith(
        headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: fg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: fg),
        actionsIconTheme: IconThemeData(color: fg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: dark ? const Color(0xFF3A1A66) : const Color(0xFFE9DDF5),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              color: states.contains(WidgetState.selected) ? fg : muted,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? (dark ? const Color(0xFFD9B8FF) : purpleMid)
                  : muted,
            )),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onAccent,
        elevation: 4,
        shape: const StadiumBorder(),
        extendedTextStyle:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dark ? accent : purple,
          foregroundColor: dark ? onAccent : Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? Colors.white : purple,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide(color: dark ? Colors.white : purple, width: 1.6),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? Colors.white : purple,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: Color(0x33000000)),
        selectedColor: accent,
        checkmarkColor: onAccent,
        labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : purple),
        secondaryLabelStyle:
            TextStyle(fontWeight: FontWeight.w800, color: onAccent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: header,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: cyan,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      // Colours are set explicitly: a title style without a colour left list
      // text white on the light theme.
      listTileTheme: ListTileThemeData(
        textColor: fg,
        iconColor: muted,
        titleTextStyle: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 16, color: fg),
        subtitleTextStyle: TextStyle(fontSize: 14, color: muted),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
          color: dark ? cyan : purpleMid),
    );
  }
}
