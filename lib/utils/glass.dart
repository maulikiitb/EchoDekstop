import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../services/settings_manager.dart';

/// A "liquid glass" panel: blurred backdrop, soft tint, bright edge highlight.
/// Falls back to a plain solid panel when glass is disabled in settings.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.tint,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsManager>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final br = BorderRadius.circular(radius);
    final base = tint ?? scheme.surfaceContainerHigh;
    final inner = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    if (!s.glassEnabled) {
      return DecoratedBox(
        decoration: BoxDecoration(color: base, borderRadius: br),
        child: ClipRRect(borderRadius: br, child: inner),
      );
    }

    // Real liquid-glass rendering comes from the liquid_glass_widgets package.
    return GlassContainer(
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: LiquidRoundedSuperellipse(borderRadius: radius),
      padding: padding,
      clipBehavior: Clip.antiAlias,
      settings: LiquidGlassSettings(
        blur: math.max(0.01, s.glassBlur),
        thickness: 18,
        glassColor: base.withValues(alpha: s.glassOpacity),
        lightIntensity: isDark ? 0.5 : 0.7,
        saturation: 1.3,
      ),
      child: child,
    );
  }
}
