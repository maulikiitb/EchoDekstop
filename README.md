# Echo Music Desktop

A Windows desktop build of the open-source **Echo Music** player, with a heavily
customisable "liquid glass" interface. Built with Flutter.

> Unofficial personal build. Based on the Flutter desktop port of
> [Echo Music](https://github.com/iad1tya/Echo-Music) by iad1tya (GPL-3.0).
> Streams through `youtube_explode_dart`; not affiliated with YouTube or Google.

## Download

Every push to `main` builds the app on GitHub Actions: open the **Actions** tab,
pick the latest green run and download the **EchoMusic-Windows** artifact. Tagged
versions (`v*`) are published on the **Releases** page. Unzip the folder and run
`echo.exe` (keep the other files next to it). Windows SmartScreen may warn about an
unsigned app: *More info → Run anyway*.

## Customisation (Settings → Appearance)

| Area | Options |
| --- | --- |
| Presets | One-tap looks: Midnight, Sunset, Ocean, Forest, Rose, Frost, Mono |
| Theme | Light / dark / system, AMOLED black, 10 accent swatches + custom colour, Windows accent, dynamic album colours |
| Background | Solid, gradient, animated aurora, or blurred album art, with dimming |
| Liquid glass | Frosted sidebar, player bar and cards with adjustable blur and tint |
| Typography | 17 fonts, letter spacing, word spacing, text size |
| Layout | Sidebar auto / compact / expanded, corner roundness |
| Window (Windows) | None, Mica, Acrylic, Tabbed |

**Player settings:** streaming / download quality, auto-add similar songs, playback
speed (0.5x to 2x), lyrics size, alignment and glow.

## Keyboard shortcuts

| Key | Action |
| --- | --- |
| Space | Play / pause |
| Left / Right | Seek 5 s |
| Ctrl + Left / Right, P / N | Previous / next |
| Up / Down | Volume |
| M | Mute |
| Media keys | Play/pause, next, previous (while the window is focused) |

Shortcuts pause themselves while you are typing in a text field.

## Build it yourself

    flutter config --enable-windows-desktop
    flutter pub get
    flutter run -d windows            # or: flutter build windows --release

Needs Flutter (stable) and Visual Studio 2022 with *Desktop development with C++*.

## Known limitations

* Playback relies on YouTube's current behaviour; if a song cannot be played, the
  reason is shown at the bottom of the app.
* Fonts are downloaded the first time they are used (internet needed).
* Mica / Tabbed need Windows 11; Acrylic can feel laggy while dragging the window.
* Global media keys (when another app is focused) are not supported yet.

## License

GPL-3.0, inherited from the original project. See [LICENSE](LICENSE).
