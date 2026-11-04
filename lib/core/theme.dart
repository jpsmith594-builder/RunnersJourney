import 'package:flutter/material.dart';

/// The app's look: bright, bold and modern. A hot orange as the main colour
/// with teal and violet as partners.
class AppTheme {
  static const Color orange = Color(0xFFFF5A1F);
  static const Color teal = Color(0xFF00BFA6);
  static const Color violet = Color(0xFF7B3FF2);

  static ThemeData light() => _build(
        ColorScheme.fromSeed(
          seedColor: orange,
          brightness: Brightness.light,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        ).copyWith(
          primary: orange,
          onPrimary: Colors.white,
          secondary: teal,
          onSecondary: Colors.white,
          tertiary: violet,
          onTertiary: Colors.white,
          surface: const Color(0xFFF7F8FF),
        ),
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: orange,
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        ).copyWith(
          primary: const Color(0xFFFF7A45),
          onPrimary: const Color(0xFF2B0C00),
          secondary: const Color(0xFF2EE6C8),
          onSecondary: const Color(0xFF00201B),
          tertiary: const Color(0xFFA37BFF),
          onTertiary: const Color(0xFF1B0B45),
        ),
      );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final t = base.textTheme;
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: t.copyWith(
        headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: scheme.onPrimary),
        actionsIconTheme: IconThemeData(color: scheme.onPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            )),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        elevation: 4,
        extendedTextStyle:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: BorderSide(color: scheme.primary, width: 1.6),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        selectedColor: scheme.primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
