import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../../../services/media_player.dart';
import '../../../services/settings_manager.dart';
import '../widgets/setting_item.dart';
import '../widgets/setting_slider.dart';

class PlayerSettingsPage extends StatelessWidget {
  const PlayerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Player')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              const GroupTitle(title: 'Audio quality'),
              SettingTile(
                title: 'Streaming quality',
                subtitle: 'Used when playing online',
                leading: const Icon(Icons.graphic_eq),
                isFirst: true,
                trailing: SegmentedButton<AudioQuality>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: AudioQuality.low, label: Text('Low')),
                    ButtonSegment(
                        value: AudioQuality.high, label: Text('High')),
                  ],
                  selected: {s.streamingQuality},
                  onSelectionChanged: (v) => s.streamingQuality = v.first,
                ),
              ),
              SettingTile(
                title: 'Download quality',
                leading: const Icon(Icons.download_rounded),
                isLast: true,
                trailing: SegmentedButton<AudioQuality>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: AudioQuality.low, label: Text('Low')),
                    ButtonSegment(
                        value: AudioQuality.high, label: Text('High')),
                  ],
                  selected: {s.downloadQuality},
                  onSelectionChanged: (v) => s.downloadQuality = v.first,
                ),
              ),
              const GroupTitle(title: 'Playback'),
              SettingSwitchTile(
                title: 'Auto-add similar songs',
                subtitle: 'Keep the queue filling up when it runs low',
                leading: const Icon(Icons.auto_awesome),
                isFirst: true,
                value: s.autofetchSongs,
                onChanged: (v) => s.autofetchSongs = v,
              ),
              if (!Platform.isWindows)
                SettingSwitchTile(
                  title: 'Skip silence',
                  leading: const Icon(Icons.fast_forward),
                  value: s.skipSilence,
                  onChanged: (v) => GetIt.I<MediaPlayer>().skipSilence(v),
                ),
              SettingSlider(
                label: 'Playback speed  ${s.playbackSpeed.toStringAsFixed(2)}x',
                icon: Icons.speed,
                value: s.playbackSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 30,
                isLast: true,
                onChanged: (v) => GetIt.I<MediaPlayer>()
                    .setPlaybackSpeed(double.parse(v.toStringAsFixed(2))),
              ),
              const GroupTitle(title: 'Lyrics'),
              SettingSlider(
                label: 'Lyrics size  ${(s.lyricsScale * 100).round()}%',
                icon: Icons.format_size,
                value: s.lyricsScale,
                min: 0.7,
                max: 1.6,
                divisions: 18,
                isFirst: true,
                onChanged: (v) => s.lyricsScale = v,
              ),
              SettingTile(
                title: 'Lyrics alignment',
                leading: const Icon(Icons.format_align_center),
                trailing: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Left')),
                    ButtonSegment(value: 1, label: Text('Centre')),
                    ButtonSegment(value: 2, label: Text('Right')),
                  ],
                  selected: {s.lyricsAlign},
                  onSelectionChanged: (v) => s.lyricsAlign = v.first,
                ),
              ),
              SettingSlider(
                label: 'Lyrics glow  ${(s.lyricsGlow * 100).round()}%',
                icon: Icons.flare,
                value: s.lyricsGlow,
                min: 0,
                max: 1.5,
                divisions: 15,
                isLast: true,
                onChanged: (v) => s.lyricsGlow = v,
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
