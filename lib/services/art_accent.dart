import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:palette_generator/palette_generator.dart';

import 'media_player.dart';

/// The most vibrant colour of the current song's artwork. The UI uses it as
/// its accent when "Dynamic album colours" is switched on.
final ValueNotifier<Color?> artAccentColor = ValueNotifier<Color?>(null);

Uri? _lastArt;

void startArtAccent() {
  final player = GetIt.I<MediaPlayer>();
  player.currentSongNotifier.addListener(() async {
    final uri = player.currentSongNotifier.value?.artUri;
    if (uri == null || uri == _lastArt) return;
    _lastArt = uri;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(uri.toString()),
        size: const Size(120, 120),
        maximumColorCount: 12,
      );
      if (_lastArt != uri) return; // a newer song already took over
      artAccentColor.value = (palette.vibrantColor ??
              palette.lightVibrantColor ??
              palette.dominantColor)
          ?.color;
    } catch (e) {
      debugPrint('Artwork colour extraction failed: $e');
    }
  });
}
