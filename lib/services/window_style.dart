import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

/// Applies Windows 11 window materials (Mica / Acrylic / Tabbed).
class WindowStyle {
  static bool _ready = false;
  static int _lastMaterial = -1;
  static bool? _lastDark;

  static Future<void> init() async {
    if (!Platform.isWindows) return;
    try {
      await Window.initialize();
      _ready = true;
    } catch (e) {
      debugPrint('Window effects unavailable: $e');
    }
  }

  static Future<void> apply(int material, bool dark) async {
    if (!_ready) return;
    if (material == _lastMaterial && dark == _lastDark) return;
    _lastMaterial = material;
    _lastDark = dark;
    try {
      final effect = switch (material) {
        1 => WindowEffect.mica,
        2 => WindowEffect.acrylic,
        3 => WindowEffect.tabbed,
        _ => WindowEffect.disabled,
      };
      await Window.setEffect(effect: effect, dark: dark);
    } catch (e) {
      debugPrint('Could not apply window effect: $e');
    }
  }
}
