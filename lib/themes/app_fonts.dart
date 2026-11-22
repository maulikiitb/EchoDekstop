import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/settings_manager.dart';

/// Central place for the user-selectable typography.
class AppFonts {
  static const String systemDefault = 'System default';

  static const List<String> families = [
    'Poppins',
    'Inter',
    'Roboto',
    'Montserrat',
    'Outfit',
    'Lexend',
    'Nunito',
    'DM Sans',
    'Manrope',
    'Sora',
    'Space Grotesk',
    'Raleway',
    'Playfair Display',
    'Lora',
    'JetBrains Mono',
    'Orbitron',
    'Pacifico',
    systemDefault,
  ];

  /// Base style used by hand-written text styles (replaces the old
  /// hard-coded Poppins).
  static TextStyle style() {
    final SettingsManager? sm =
        GetIt.I.isRegistered<SettingsManager>() ? GetIt.I<SettingsManager>() : null;
    final family = sm?.fontFamily ?? 'Poppins';
    TextStyle base = const TextStyle();
    if (family != systemDefault) {
      try {
        base = GoogleFonts.getFont(family);
      } catch (_) {}
    }
    return base.copyWith(
      letterSpacing: sm?.letterSpacing,
      wordSpacing: sm?.wordSpacing,
    );
  }

  static TextTheme textTheme(
    TextTheme base, {
    required String family,
    double letterSpacing = 0,
    double wordSpacing = 0,
  }) {
    TextTheme t = base;
    if (family != systemDefault) {
      try {
        t = GoogleFonts.getTextTheme(family, base);
      } catch (_) {}
    }
    TextStyle? f(TextStyle? s) => s?.copyWith(
          letterSpacing: (s.letterSpacing ?? 0) + letterSpacing,
          wordSpacing: (s.wordSpacing ?? 0) + wordSpacing,
        );
    return t.copyWith(
      displayLarge: f(t.displayLarge),
      displayMedium: f(t.displayMedium),
      displaySmall: f(t.displaySmall),
      headlineLarge: f(t.headlineLarge),
      headlineMedium: f(t.headlineMedium),
      headlineSmall: f(t.headlineSmall),
      titleLarge: f(t.titleLarge),
      titleMedium: f(t.titleMedium),
      titleSmall: f(t.titleSmall),
      bodyLarge: f(t.bodyLarge),
      bodyMedium: f(t.bodyMedium),
      bodySmall: f(t.bodySmall),
      labelLarge: f(t.labelLarge),
      labelMedium: f(t.labelMedium),
      labelSmall: f(t.labelSmall),
    );
  }
}
