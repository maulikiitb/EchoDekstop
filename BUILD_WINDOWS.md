# Building Echo Music for Windows

## Easiest: GitHub Actions
1. Create a new GitHub repository and upload everything in this folder (keep the `.github` folder).
2. Open the **Actions** tab, choose **Build Windows**, press **Run workflow**.
3. When it finishes, download the `EchoMusic-Windows` artifact, unzip it, and run `echo.exe`.

## Locally
Install Flutter (stable) and Visual Studio 2022 with "Desktop development with C++", then:

    flutter config --enable-windows-desktop
    flutter pub get
    flutter run -d windows        # or: flutter build windows --release

## Keyboard shortcuts
Space = play/pause, Left/Right = seek 5 s, Ctrl+Left/Right = previous/next, media keys.
Customisation: Settings > Appearance.
