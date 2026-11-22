import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:window_manager/window_manager.dart';

import '../services/media_player.dart';
import '../services/window_style.dart';
import 'glass.dart';

/// Compact always-on-top player shown when the window is in mini mode.
class MiniPlayerView extends StatelessWidget {
  const MiniPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final mp = GetIt.I<MediaPlayer>();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => windowManager.startDragging(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Glass(
            radius: 22,
            padding: const EdgeInsets.all(10),
            child: ValueListenableBuilder<MediaItem?>(
              valueListenable: mp.currentSongNotifier,
              builder: (context, song, _) {
                final art = song?.artUri;
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: art == null
                            ? ColoredBox(
                                color: scheme.surfaceContainerHighest,
                                child: const Icon(Icons.music_note))
                            : Image.network(
                                art.toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                    color: scheme.surfaceContainerHighest,
                                    child: const Icon(Icons.music_note)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song?.title ?? 'Nothing playing',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            song?.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 6),
                          ValueListenableBuilder<ProgressBarState>(
                            valueListenable: mp.progressBarState,
                            builder: (context, p, _) {
                              final total = p.total.inMilliseconds;
                              return LinearProgressIndicator(
                                value: total <= 0
                                    ? 0
                                    : (p.current.inMilliseconds / total)
                                        .clamp(0.0, 1.0)
                                        .toDouble(),
                                minHeight: 3,
                                borderRadius: BorderRadius.circular(2),
                              );
                            },
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.skip_previous),
                                onPressed: () => mp.player.seekToPrevious(),
                              ),
                              ValueListenableBuilder<ButtonState>(
                                valueListenable: mp.buttonState,
                                builder: (context, st, _) => IconButton(
                                  icon: Icon(
                                      st == ButtonState.playing
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      size: 34),
                                  onPressed: () => mp.player.playing
                                      ? mp.player.pause()
                                      : mp.player.play(),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.skip_next),
                                onPressed: () => mp.player.seekToNext(),
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Back to full app',
                                icon: const Icon(Icons.open_in_full),
                                onPressed: () => WindowStyle.setMini(false),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
