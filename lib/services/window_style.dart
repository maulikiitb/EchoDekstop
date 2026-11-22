import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';

/// Native window handling for Windows: materials (Mica/Acrylic), custom title
/// bar, always-on-top, opacity and remembering the window size.
class WindowStyle {
  static bool _acrylicReady = false;
  static bool _managerReady = false;
  static int _lastMaterial = -1;
  static bool? _lastDark;
  static bool? _lastTitleBar;
  static bool? _lastOnTop;
  static double? _lastOpacity;

  static bool get managerReady => _managerReady;

  /// True while the compact always-on-top mini player is shown.
  static final ValueNotifier<bool> miniMode = ValueNotifier<bool>(false);
  static Size? _savedSize;

  static Future<void> setMini(bool on) async {
    if (!_managerReady || miniMode.value == on) return;
    try {
      if (on) {
        _savedSize = await windowManager.getSize();
        await windowManager.setMinimumSize(const Size(320, 130));
        await windowManager.setSize(const Size(440, 150));
        await windowManager.setAlwaysOnTop(true);
        _lastOnTop = true;
      } else {
        await windowManager.setMinimumSize(const Size(900, 600));
        await windowManager.setSize(_savedSize ?? const Size(1280, 780));
        final bool top = Hive.box('SETTINGS').get('ALWAYS_ON_TOP', defaultValue: false);
        await windowManager.setAlwaysOnTop(top);
        _lastOnTop = top;
      }
      miniMode.value = on;
    } catch (e) {
      debugPrint('Mini player toggle failed: $e');
    }
  }

  /// Call once after Hive is open and before runApp.
  static Future<void> init() async {
    if (!Platform.isWindows) return;
    try {
      await Window.initialize();
      _acrylicReady = true;
    } catch (e) {
      debugPrint('Window effects unavailable: $e');
    }

    try {
      await windowManager.ensureInitialized();
      final box = Hive.box('SETTINGS');
      final double w = (box.get('WINDOW_W', defaultValue: 1280.0) as num).toDouble();
      final double h = (box.get('WINDOW_H', defaultValue: 780.0) as num).toDouble();
      final bool customBar = box.get('CUSTOM_TITLEBAR', defaultValue: true);
      final options = WindowOptions(
        size: Size(w.clamp(900.0, 4000.0).toDouble(), h.clamp(600.0, 3000.0).toDouble()),
        minimumSize: const Size(900, 600),
        center: true,
        title: 'Echo Music',
      );
      await windowManager.waitUntilReadyToShow(options, () async {
        try {
          if (customBar) {
            await windowManager.setTitleBarStyle(TitleBarStyle.hidden,
                windowButtonVisibility: false);
            _lastTitleBar = true;
          }
        } catch (e) {
          debugPrint('Custom title bar unavailable: $e');
        }
        await windowManager.setMinimumSize(const Size(900, 600));
        await windowManager.show();
        await windowManager.focus();
      });
      windowManager.addListener(_SizeSaver());
      _managerReady = true;
    } catch (e) {
      debugPrint('Window manager unavailable: $e');
    }
  }

  static Future<void> apply({
    required int material,
    required bool dark,
    required bool customTitleBar,
    required bool alwaysOnTop,
    required double opacity,
  }) async {
    if (!Platform.isWindows) return;

    if (_acrylicReady && (material != _lastMaterial || dark != _lastDark)) {
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

    if (!_managerReady) return;
    try {
      if (customTitleBar != _lastTitleBar) {
        _lastTitleBar = customTitleBar;
        await windowManager.setTitleBarStyle(
          customTitleBar ? TitleBarStyle.hidden : TitleBarStyle.normal,
          windowButtonVisibility: !customTitleBar,
        );
      }
      if (alwaysOnTop != _lastOnTop) {
        _lastOnTop = alwaysOnTop;
        await windowManager.setAlwaysOnTop(alwaysOnTop);
      }
      if (opacity != _lastOpacity) {
        _lastOpacity = opacity;
        await windowManager.setOpacity(opacity);
      }
    } catch (e) {
      debugPrint('Window option failed: $e');
    }
  }
}

class _SizeSaver with WindowListener {
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void onWindowResized() async {
    final now = DateTime.now();
    if (now.difference(_last).inMilliseconds < 400) return;
    _last = now;
    if (WindowStyle.miniMode.value) return;
    try {
      if (await windowManager.isMaximized() ||
          await windowManager.isFullScreen()) {
        return;
      }
      final size = await windowManager.getSize();
      final box = Hive.box('SETTINGS');
      await box.put('WINDOW_W', size.width);
      await box.put('WINDOW_H', size.height);
    } catch (_) {}
  }
}
