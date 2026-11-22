import 'package:flutter/material.dart';

/// Lets non-UI code (e.g. the audio player) show a message to the user.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showAppMessage(String text,
    {Duration duration = const Duration(seconds: 6)}) {
  rootMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis),
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ));
}
