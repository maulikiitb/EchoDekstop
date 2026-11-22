import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
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

    final sigma = math.max(0.01, s.glassBlur);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: br,
              color: base.withValues(alpha: s.glassOpacity),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.14 : 0.5),
                  Colors.white.withValues(alpha: isDark ? 0.03 : 0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.6),
                width: 1,
              ),
            ),
            child: inner,
          ),
        ),
      ),
    );
  }
}
