import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import '../services/media_player.dart';
import '../services/settings_manager.dart';

/// Paints the window background according to the user's chosen style:
/// 0 solid, 1 gradient, 2 aurora, 3 blurred album art.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  /// How opaque the whole background is for each window material.
  static double materialAlpha(int material) {
    switch (material) {
      case 1: // mica
      case 3: // tabbed
        return 0.55;
      case 2: // acrylic
        return 0.7;
      default:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsManager>();
    final scheme = Theme.of(context).colorScheme;

    Widget bg;
    switch (s.backgroundStyle) {
      case 0:
        bg = ColoredBox(color: scheme.surface);
        break;
      case 2:
        bg = AuroraBackground(animated: s.backgroundAnimated, dim: s.backgroundDim);
        break;
      case 3:
        bg = AlbumArtBackground(dim: s.backgroundDim);
        break;
      default:
        bg = const GradientBackground();
    }

    final alpha = materialAlpha(s.windowMaterial);
    if (alpha < 1.0) bg = Opacity(opacity: alpha, child: bg);
    return RepaintBoundary(child: bg);
  }
}

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.14), scheme.surface),
            scheme.surface,
            Color.alphaBlend(
                scheme.tertiary.withValues(alpha: 0.12), scheme.surface),
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Slowly drifting, soft colour blobs.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.animated, required this.dim});
  final bool animated;
  final double dim;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 40));
    if (widget.animated) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant AuroraBackground old) {
    super.didUpdateWidget(old);
    if (widget.animated && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animated && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(Color color, Alignment a, double size, double alpha) {
    return Align(
      alignment: a,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context).shortestSide * 1.3;
    final alpha = (1.0 - widget.dim).clamp(0.15, 0.6).toDouble();
    return ColoredBox(
      color: scheme.surface,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 2 * math.pi;
          return Stack(
            fit: StackFit.expand,
            children: [
              _blob(scheme.primary,
                  Alignment(math.sin(t) * 0.9, math.cos(t * 0.8) * 0.9), size, alpha),
              _blob(scheme.tertiary,
                  Alignment(math.sin(t + 2.1) * 0.9, math.cos(t * 0.8 + 1.7) * 0.9),
                  size, alpha),
              _blob(scheme.secondary,
                  Alignment(math.sin(t + 4.2) * 0.9, math.cos(t * 0.8 + 3.4) * 0.9),
                  size * 0.85, alpha * 0.8),
            ],
          );
        },
      ),
    );
  }
}

/// The current song's artwork, heavily blurred and dimmed.
class AlbumArtBackground extends StatelessWidget {
  const AlbumArtBackground({super.key, required this.dim});
  final double dim;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<MediaItem?>(
      valueListenable: GetIt.I<MediaPlayer>().currentSongNotifier,
      builder: (context, item, _) {
        final uri = item?.artUri;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          child: uri == null
              ? const KeyedSubtree(
                  key: ValueKey('no-art'), child: GradientBackground())
              : KeyedSubtree(
                  key: ValueKey(uri.toString()),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: scheme.surface),
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(
                            sigmaX: 60, sigmaY: 60, tileMode: TileMode.mirror),
                        child: Image.network(
                          uri.toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                      ColoredBox(color: scheme.surface.withValues(alpha: dim)),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
