import 'dart:io';

import 'package:Echo/services/yt_audio_stream.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Resolves a real video and downloads its first bytes with the same code the
/// app uses. Run by the "Playback check" GitHub workflow.
void main() {
  test('can resolve and download audio', () async {
    HttpOverrides.global = null; // allow real network inside flutter test
    final yt = YoutubeExplode();
    final manifest = await fetchStreamManifest(yt, 'dQw4w9WgXcQ');
    final audio = manifest.audioOnly.sortByBitrate().last;
    // ignore: avoid_print
    print('PLAYBACK_CHECK stream ${audio.container.name} '
        '${audio.bitrate} bps, ${audio.size.totalBytes} bytes');
    var received = 0;
    await for (final chunk in rangedAudioStream(audio.url, 0, 99999)) {
      received += chunk.length;
    }
    // ignore: avoid_print
    print('PLAYBACK_CHECK downloaded $received bytes');
    expect(received, greaterThan(50000));
    yt.close();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
