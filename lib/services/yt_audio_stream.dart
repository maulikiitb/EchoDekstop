import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeAudioSource extends StreamAudioSource {
  final String videoId;
  final String quality; // 'high' or 'low'
  final YoutubeExplode ytExplode;
  AudioOnlyStreamInfo? _cachedStreamInfo;

  YouTubeAudioSource({
    required this.videoId,
    required this.quality,
    super.tag,
  }) : ytExplode = YoutubeExplode();

  Future<AudioOnlyStreamInfo> _getStreamInfo() async {
    if (_cachedStreamInfo != null) return _cachedStreamInfo!;

    final manifest = await fetchStreamManifest(ytExplode, videoId);
    Iterable<AudioOnlyStreamInfo> supportedStreams = manifest.audioOnly;
    if (Platform.isMacOS || Platform.isIOS) {
      final mp4Streams = supportedStreams
          .where((s) => s.container.name == 'mp4' || s.container.name == 'm4a')
          .toList();
      if (mp4Streams.isNotEmpty) {
        supportedStreams = mp4Streams;
      }
    }
    supportedStreams = supportedStreams.sortByBitrate();

    final audioStream = quality == 'high'
        ? supportedStreams.lastOrNull
        : supportedStreams.firstOrNull;

    if (audioStream == null) {
      throw Exception('No audio stream available for this video.');
    }

    _cachedStreamInfo = audioStream;
    return audioStream;
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    try {
      final audioStream = await _getStreamInfo();

      start ??= 0;
      end ??= (audioStream.isThrottled
          ? (end ?? (start + 10379935))
          : audioStream.size.totalBytes);
      if (end > audioStream.size.totalBytes) {
        end = audioStream.size.totalBytes;
      }

      final stream = await _downloadStream(audioStream.url, start, end - 1);
      return StreamAudioResponse(
        sourceLength: audioStream.size.totalBytes,
        contentLength: end - start,
        offset: start,
        stream: stream,
        contentType: audioStream.codec.mimeType,
      );
    } catch (e) {
      throw Exception('Failed to load audio: $e');
    }
  }
}

final YoutubeExplode ytExplode = YoutubeExplode();

/// Starts a generic HTTP server that listens for requests to stream YouTube audio.
///
/// Clients must pass 'id' and 'quality' as URL query parameters.
/// The server binds to a random available port.
/// Returns the base URL for the streaming endpoint.
Future<String> createAudioStreamServer() async {
  // Bind to a random port (port 0) on the loopback interface.
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

  // Listen for requests and dispatch them to the handler
  server.listen((HttpRequest request) {
    // Pass only the request object to the handler
    handleAudioRequest(request);
  });

  // Construct the base streaming URL
  final host = server.address.host;
  final port = server.port;
  final url = 'http://$host:$port/audio';

  print(
      'Generic streaming server started on $url. Use ?id=...&quality=... to stream.');

  // You would typically return the server instance here too, if you needed
  // to close it later (e.g., return {'server': server, 'url': url})
  return url;
}

// ----------------------------------------------------------------------------
// HANDLER FUNCTION (Modified to read parameters from the request URI)
// ----------------------------------------------------------------------------

final Map<String, ({AudioOnlyStreamInfo info, DateTime expiry})>
    _manifestCache = {};

Future<void> handleAudioRequest(HttpRequest request) async {
  final response = request.response;

  // 1. Check the path and extract parameters from URL query
  if (request.uri.path != '/audio') {
    response.statusCode = HttpStatus.notFound;
    response.write('404 Not Found');
    await response.close();
    return;
  }

  final queryParams = request.uri.queryParameters;
  final videoId = queryParams['id'];
  final quality = queryParams['quality'] ?? 'high'; // Default to 'high'

  if (videoId == null || videoId.isEmpty) {
    response.statusCode = HttpStatus.badRequest;
    response.write('Missing required query parameter: id');
    await response.close();
    return;
  }

  print('Processing request for video ID: $videoId (Quality: $quality)');

  try {
    AudioOnlyStreamInfo? audioStreamInfo;

    // Check Cache
    if (_manifestCache.containsKey(videoId)) {
      final cached = _manifestCache[videoId]!;
      if (DateTime.now().isBefore(cached.expiry)) {
        print('Using cached manifest for $videoId');
        audioStreamInfo = cached.info;
      } else {
        _manifestCache.remove(videoId);
      }
    }

    if (audioStreamInfo == null) {
      // 2. Get the Stream Manifest and select the audio stream
      final manifest = await fetchStreamManifest(ytExplode, videoId);

      Iterable<AudioOnlyStreamInfo> supportedStreams = manifest.audioOnly;
      if (Platform.isMacOS || Platform.isIOS) {
        final mp4Streams = supportedStreams
            .where(
                (s) => s.container.name == 'mp4' || s.container.name == 'm4a')
            .toList();
        if (mp4Streams.isNotEmpty) {
          supportedStreams = mp4Streams;
        }
      }
      supportedStreams = supportedStreams.sortByBitrate();

      audioStreamInfo = quality == 'high'
          ? supportedStreams.lastOrNull
          : supportedStreams.firstOrNull;

      if (audioStreamInfo != null) {
        _manifestCache[videoId] = (
          info: audioStreamInfo,
          expiry: DateTime.now().add(const Duration(hours: 1))
        );
      }
    }

    if (audioStreamInfo == null) {
      response.statusCode = HttpStatus.internalServerError;
      response.write('No audio stream available for video $videoId.');
      await response.close();
      return;
    }

    final totalLength = audioStreamInfo.size.totalBytes;

    // 3. Parse the client's 'Range' header (same logic)

    (int start, int end)? parseRange(String rangeHeader, int totalLength) {
      // Expected format: "bytes=start-end" or "bytes=start-"
      if (!rangeHeader.startsWith('bytes=')) return null;

      final parts = rangeHeader.substring(6).split('-');
      if (parts.length != 2) return null;

      final startStr = parts[0];
      final endStr = parts[1];

      final start = int.tryParse(startStr) ?? 0;

      // If end is missing (e.g., "bytes=1000-"), it means until the end of the file
      final end = endStr.isEmpty ? totalLength - 1 : int.tryParse(endStr);

      if (end == null ||
          end >= totalLength ||
          start >= totalLength ||
          start > end) {
        return null; // Invalid range or past the end of the file
      }

      return (start, end);
    }

    int start = 0;
    int end = totalLength - 1;
    bool isPartial = false;

    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    if (rangeHeader != null) {
      final range = parseRange(rangeHeader, totalLength);
      if (range != null) {
        start = range.$1;
        end = range.$2;
        isPartial = true;
      }
    }

    // 4. Get the *actual* byte stream from YouTube
    final stream = await _downloadStream(audioStreamInfo.url, start, end);

    // 5. Set the HTTP headers and pipe the stream
    final mimeType = audioStreamInfo.codec.mimeType;

    response.statusCode = isPartial ? HttpStatus.partialContent : HttpStatus.ok;
    response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    response.headers.contentType = ContentType.parse(mimeType);
    // Don't set contentLength - use chunked transfer encoding instead
    // This avoids Content size exceeds specified contentLength errors
    if (isPartial) {
      response.headers.set(
          HttpHeaders.contentRangeHeader, 'bytes $start-$end/$totalLength');
    }
    response.bufferOutput = false;

    // Collect bytes and write to avoid content length mismatch
    try {
      await for (final chunk in stream) {
        response.add(chunk);
      }
    } catch (streamError) {
      print('Stream error for $videoId: $streamError');
    }

    await response.close();
    print(
        '[$videoId] Served ${isPartial ? 'partial' : 'full'} stream: bytes $start-$end');
  } catch (e) {
    print('Error serving audio for ID $videoId: $e');
    try {
      response.statusCode = HttpStatus.internalServerError;
      response.write('Error: $e');
      await response.close();
    } catch (_) {}
  }
}

// ----------------------------------------------------------------------------
// URL CACHING TO IMPROVE LOAD SPEED
// ----------------------------------------------------------------------------
final Map<String, ({String url, DateTime expiry})> _urlCache = {};

// Singleton YoutubeExplode instance for faster URL fetching
final YoutubeExplode _ytClient = YoutubeExplode();

Future<AudioSource> getDirectUrlAudioSource(
    String videoId, String quality, dynamic tag) async {
  // 1. Check Cache first - this is instant
  if (_urlCache.containsKey(videoId)) {
    final cached = _urlCache[videoId]!;
    if (DateTime.now().isBefore(cached.expiry)) {
      return AudioSource.uri(Uri.parse(cached.url), tag: tag);
    } else {
      _urlCache.remove(videoId); // Expired
    }
  }

  try {
    // 2. Fetch Manifest using singleton client (faster than creating new instance)
    final manifest = await fetchStreamManifest(_ytClient, videoId);
    Iterable<AudioOnlyStreamInfo> supportedStreams = manifest.audioOnly;

    // Filter for mp4/m4a on Apple platforms for better compatibility
    if (Platform.isMacOS || Platform.isIOS) {
      final mp4Streams = supportedStreams
          .where((s) => s.container.name == 'mp4' || s.container.name == 'm4a')
          .toList();
      if (mp4Streams.isNotEmpty) {
        supportedStreams = mp4Streams;
      }
    }
    supportedStreams = supportedStreams.sortByBitrate();

    final audioStream = quality == 'high'
        ? supportedStreams.lastOrNull
        : supportedStreams.firstOrNull;

    if (audioStream == null) {
      throw Exception('No audio stream available for this video.');
    }

    // 3. Cache the URL for 1 hour
    _urlCache[videoId] = (
      url: audioStream.url.toString(),
      expiry: DateTime.now().add(const Duration(hours: 1))
    );

    return AudioSource.uri(audioStream.url, tag: tag);
  } catch (e) {
    print('Error fetching URL for $videoId: $e');
    rethrow;
  }
}

/// YouTube changes which player clients work every few weeks, so try the
/// library's own automatic selection first and then fall back to others.
Future<StreamManifest> fetchStreamManifest(
    YoutubeExplode yt, String videoId) async {
  final attempts = <List<YoutubeApiClient>?>[
    null, // library default (handles its own fallbacks)
    [YoutubeApiClient.androidVr],
    [YoutubeApiClient.tv],
    [YoutubeApiClient.mweb],
    [YoutubeApiClient.androidSdkless],
  ];
  Object? lastError;
  for (final clients in attempts) {
    try {
      final manifest = clients == null
          ? await yt.videos.streamsClient.getManifest(videoId)
          : await yt.videos.streamsClient
              .getManifest(videoId, ytClients: clients);
      if (manifest.audioOnly.isNotEmpty) return manifest;
    } catch (e) {
      lastError = e;
    }
  }
  throw Exception('No playable audio stream found: $lastError');
}

const _browserUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36';

/// Downloads bytes [start]..[end] (inclusive) in <=~10 MB chunks using the
/// `range` query parameter, which is what YouTube's CDN expects.
Future<Stream<List<int>>> _downloadStream(Uri url, int start, int end) async {
  return _rangedStream(url, start, end);
}

Stream<List<int>> _rangedStream(Uri url, int start, int end) async* {
  const chunk = 9898989;
  final client = HttpClient();
  try {
    var pos = start;
    while (pos <= end) {
      final to = (pos + chunk - 1) < end ? (pos + chunk - 1) : end;
      final params = Map<String, String>.from(url.queryParameters)
        ..['range'] = '$pos-$to';
      final request = await client.getUrl(url.replace(queryParameters: params));
      request.headers.set(HttpHeaders.userAgentHeader, _browserUserAgent);
      final response = await request.close();
      if (response.statusCode >= 400) {
        throw HttpException('Audio request failed: HTTP ${response.statusCode}');
      }
      await for (final data in response) {
        yield data;
      }
      pos = to + 1;
    }
  } finally {
    client.close(force: true);
  }
}

/// Public wrapper used by the playback self-test (test/playback_check_test.dart).
Stream<List<int>> rangedAudioStream(Uri url, int start, int end) =>
    _rangedStream(url, start, end);

// ----------------------------------------------------------------------------
// DESKTOP PLAYBACK: download to a local cache file, then play the file.
// libmpv reads the duration and seeks reliably from a real file, whereas the
// on-the-fly proxy stream left the player "loading" forever with 0:00 length.
// ----------------------------------------------------------------------------
final Map<String, Future<File>> _cacheJobs = {};

Directory _audioCacheDir() {
  final dir = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}sonora_audio_cache');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

void _trimAudioCache({int keep = 60}) {
  try {
    final files = _audioCacheDir()
        .listSync()
        .whereType<File>()
        .where((f) => !f.path.endsWith('.part'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    for (final f in files.skip(keep)) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
  } catch (_) {}
}

Future<File> _downloadToCache(String videoId, String quality) async {
  final sep = Platform.pathSeparator;
  final dir = _audioCacheDir();
  // Reuse an existing complete file for this video and quality.
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.path.split(sep).last;
    if (name.startsWith('${videoId}_$quality.') && !name.endsWith('.part')) {
      if (f.lengthSync() > 10000) {
        f.setLastModifiedSync(DateTime.now());
        return f;
      }
    }
  }

  final manifest = await fetchStreamManifest(_ytClient, videoId);
  final streams = manifest.audioOnly.sortByBitrate();
  final info = quality == 'high' ? streams.lastOrNull : streams.firstOrNull;
  if (info == null) throw Exception('No audio stream available for this video.');

  final ext = info.container.name == 'webm' ? 'webm' : 'm4a';
  final target = File('${dir.path}$sep${videoId}_$quality.$ext');
  final part = File('${target.path}.part');
  final sink = part.openWrite();
  try {
    await sink.addStream(_rangedStream(info.url, 0, info.size.totalBytes - 1));
    await sink.close();
  } catch (e) {
    try {
      await sink.close();
    } catch (_) {}
    try {
      part.deleteSync();
    } catch (_) {}
    rethrow;
  }
  await part.rename(target.path);
  _trimAudioCache();
  return target;
}

/// Returns an [AudioSource] backed by a locally cached copy of the track.
Future<AudioSource> getCachedFileAudioSource(
    String videoId, String quality, dynamic tag) async {
  final job = _cacheJobs.putIfAbsent(
      '${videoId}_$quality', () => _downloadToCache(videoId, quality));
  try {
    final file = await job;
    return AudioSource.file(file.path, tag: tag);
  } finally {
    _cacheJobs.remove('${videoId}_$quality');
  }
}
