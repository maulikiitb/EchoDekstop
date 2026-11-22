import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:Echo/themes/theme.dart';
import 'package:Echo/ytmusic/modals/yt_config.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'generated/l10n.dart';
import 'services/download_manager.dart';
import 'services/file_storage.dart';
import 'services/library.dart';
import 'services/lyrics.dart';
import 'services/media_player.dart';
import 'services/settings_manager.dart';
import 'utils/router.dart';
import 'ytmusic/ytmusic.dart';
import 'services/yt_audio_stream.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initialiseHive();

  // Notification / background playback service: mobile & macOS only.
  // Initialising it on Windows/Linux throws (no platform implementation).
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.echo.music.audio',
      androidNotificationChannelName: 'Echo Music',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    );
  }

  // Initialize JustAudioMediaKit for Windows, Linux, and macOS
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    JustAudioMediaKit.ensureInitialized();
    JustAudioMediaKit.bufferSize = 8 * 1024 * 1024;
    JustAudioMediaKit.title = 'Echo Music';
    JustAudioMediaKit.prefetchPlaylist = true;
    JustAudioMediaKit.pitch = true;
  }

  String? visitorId = await Hive.box('SETTINGS').get('VISITOR_ID');

  YTMusic ytMusic = YTMusic(
    config:
        YTConfig(visitorData: visitorId ?? '', language: 'en', location: 'IN'),
    onIdUpdate: (visitorId) async {
      await Hive.box('SETTINGS').put('VISITOR_ID', visitorId);
    },
  );

  final GlobalKey<NavigatorState> panelKey = GlobalKey<NavigatorState>();

  await FileStorage.initialise();
  FileStorage fileStorage = FileStorage();
  SettingsManager settingsManager = SettingsManager();

  GetIt.I.registerSingleton<SettingsManager>(settingsManager);

  // Start Local Audio Server
  final String audioStreamUrl = await createAudioStreamServer();
  GetIt.I.registerSingleton<String>(audioStreamUrl,
      instanceName: 'audioStreamUrl');

  MediaPlayer mediaPlayer = MediaPlayer();
  GetIt.I.registerSingleton<MediaPlayer>(mediaPlayer);
  LibraryService libraryService = LibraryService();
  GetIt.I.registerSingleton<DownloadManager>(DownloadManager());
  GetIt.I.registerSingleton(panelKey);
  GetIt.I.registerSingleton<YTMusic>(ytMusic);

  GetIt.I.registerSingleton<FileStorage>(fileStorage);

  GetIt.I.registerSingleton<LibraryService>(libraryService);
  GetIt.I.registerSingleton<LyricsService>(LyricsService());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsManager),
        ChangeNotifierProvider(create: (_) => mediaPlayer),
        ChangeNotifierProvider(create: (_) => libraryService),
      ],
      child: const Echo(),
    ),
  );
}

class Echo extends StatelessWidget {
  const Echo({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final bool useDynamic = settings.dynamicColors;
        final lightTheme = AppTheme.light(
          primary: settings.accentColor,
          dynamicScheme: useDynamic ? lightDynamic : null,
          radius: settings.cornerRadius,
        );
        final darkTheme = AppTheme.dark(
          primary: settings.accentColor,
          dynamicScheme: useDynamic ? darkDynamic : null,
          amoled: settings.amoledBlack,
          radius: settings.cornerRadius,
        );
        return MaterialApp.router(
          title: 'Echo Music',
          routerConfig: router,
          locale: Locale(settings.language['value']!),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          builder: (context, child) => AppFrame(child: child ?? const SizedBox()),
        );
      },
    );
  }
}

/// Paints the app background (solid or accent gradient), applies the user's
/// text size and handles desktop keyboard shortcuts.
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child});
  final Widget child;

  bool _isTyping() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final settings = GetIt.I<SettingsManager>();
    if (!settings.keyboardShortcuts) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final player = GetIt.I<MediaPlayer>().player;

    // Media keys work even while typing.
    if (key == LogicalKeyboardKey.mediaPlayPause) {
      player.playing ? player.pause() : player.play();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaTrackNext) {
      player.seekToNext();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaTrackPrevious) {
      player.seekToPrevious();
      return KeyEventResult.handled;
    }
    if (_isTyping()) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.space && event is KeyDownEvent) {
      player.playing ? player.pause() : player.play();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (ctrl) {
        player.seekToNext();
      } else {
        player.seek(player.position + const Duration(seconds: 5));
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (ctrl) {
        player.seekToPrevious();
      } else {
        final p = player.position - const Duration(seconds: 5);
        player.seek(p < Duration.zero ? Duration.zero : p);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    final scheme = Theme.of(context).colorScheme;
    final bg = settings.gradientBackground
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.10), scheme.surface),
                scheme.surface,
                Color.alphaBlend(
                    scheme.tertiary.withValues(alpha: 0.08), scheme.surface),
              ],
            ),
          )
        : BoxDecoration(color: scheme.surface);

    final mq = MediaQuery.of(context);
    return Focus(
      onKeyEvent: _onKey,
      child: MediaQuery(
        data: mq.copyWith(textScaler: TextScaler.linear(settings.textScale)),
        child: DecoratedBox(decoration: bg, child: child),
      ),
    );
  }
}

Future<void> initialiseHive() async {
  String? applicationDataDirectoryPath;
  if (Platform.isWindows || Platform.isLinux) {
    applicationDataDirectoryPath =
        "${(await getApplicationSupportDirectory()).path}/database";
  }
  await Hive.initFlutter(applicationDataDirectoryPath);
  await Hive.openBox('SETTINGS');
  await Hive.openBox('LIBRARY');
  await Hive.openBox('SEARCH_HISTORY');
  await Hive.openBox('SONG_HISTORY');
  await Hive.openBox('FAVOURITES');
  await Hive.openBox('DOWNLOADS');
}
