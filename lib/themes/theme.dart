import 'package:flutter/material.dart';

import 'app_fonts.dart';
import 'typography.dart';

/// Builds the app themes from the user's appearance settings.
class AppTheme {
  static const _amoledContainers = (
    lowest: Color(0xFF000000),
    low: Color(0xFF0A0A0A),
    mid: Color(0xFF111111),
    high: Color(0xFF191919),
    highest: Color(0xFF222222),
  );

  static ColorScheme lightScheme({Color? accent, ColorScheme? dynamicScheme}) {
    if (dynamicScheme != null) return dynamicScheme;
    return ColorScheme.fromSeed(
      seedColor: accent ?? Colors.black,
      brightness: Brightness.light,
    );
  }

  static ColorScheme darkScheme({
    Color? accent,
    ColorScheme? dynamicScheme,
    bool amoled = true,
  }) {
    ColorScheme base;
    if (dynamicScheme != null) {
      base = dynamicScheme;
    } else if (accent != null) {
      base = ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
      );
    } else {
      base = const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white,
        onSecondary: Colors.black,
        secondaryContainer: Color(0xFF2A2A2A),
        onSecondaryContainer: Colors.white,
        surface: Colors.black,
        onSurface: Colors.white,
        error: Colors.red,
        onError: Colors.white,
      );
    }
    if (!amoled) return base;
    return base.copyWith(
      surface: Colors.black,
      surfaceDim: Colors.black,
      surfaceContainerLowest: _amoledContainers.lowest,
      surfaceContainerLow: _amoledContainers.low,
      surfaceContainer: _amoledContainers.mid,
      surfaceContainerHigh: _amoledContainers.high,
      surfaceContainerHighest: _amoledContainers.highest,
    );
  }

  static ThemeData light({
    Color? primary,
    ColorScheme? dynamicScheme,
    double radius = 20,
    String fontFamily = 'Poppins',
    double letterSpacing = 0,
    double wordSpacing = 0,
  }) =>
      _build(lightScheme(accent: primary, dynamicScheme: dynamicScheme),
          radius, fontFamily, letterSpacing, wordSpacing);

  static ThemeData dark({
    Color? primary,
    ColorScheme? dynamicScheme,
    bool amoled = true,
    double radius = 20,
    String fontFamily = 'Poppins',
    double letterSpacing = 0,
    double wordSpacing = 0,
  }) =>
      _build(
          darkScheme(
              accent: primary, dynamicScheme: dynamicScheme, amoled: amoled),
          radius,
          fontFamily,
          letterSpacing,
          wordSpacing);

  static ThemeData _build(ColorScheme scheme, double radius, String fontFamily,
      double letterSpacing, double wordSpacing) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
    );
    final isDark = scheme.brightness == Brightness.dark;
    return base.copyWith(
      // The real background is painted once by the app (see main.dart) so
      // every page can stay transparent over it.
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: AppFonts.textTheme(
        appTextTheme(base.textTheme).apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        ),
        family: fontFamily,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
      ),
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius + 4)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: isDark ? scheme.secondaryContainer : scheme.primary,
        selectedIconTheme: IconThemeData(
            color: isDark ? scheme.onSecondaryContainer : scheme.onPrimary),
        unselectedIconTheme:
            IconThemeData(color: scheme.onSurface.withValues(alpha: 0.75)),
        selectedLabelTextStyle: TextStyle(
            color: scheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.65), fontSize: 12),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(8),
        thumbColor:
            WidgetStatePropertyAll(scheme.onSurface.withValues(alpha: 0.3)),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: Map<TargetPlatform, PageTransitionsBuilder>.fromIterable(
          TargetPlatform.values,
          value: (_) => const FadeForwardsPageTransitionsBuilder(),
        ),
      ),
    );
  }
}
