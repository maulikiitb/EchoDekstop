import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/settings_manager.dart';
import '../../../utils/bottom_modals.dart';
import '../../../themes/app_fonts.dart';
import '../widgets/setting_item.dart';
import '../widgets/setting_slider.dart';


class _Preset {
  const _Preset(this.name, this.icon, this.apply);
  final String name;
  final IconData icon;
  final void Function(SettingsManager s) apply;
}

final List<_Preset> _presets = [
  _Preset('Midnight', Icons.nightlight_round, (s) {
    s.setThemeMode(ThemeMode.dark);
    s.accentColor = const Color(0xFF7C4DFF);
    s.amoledBlack = true;
    s.backgroundStyle = 2;
    s.backgroundAnimated = true;
    s.backgroundDim = 0.6;
    s.glassEnabled = true;
    s.glassBlur = 24;
    s.glassOpacity = 0.2;
  }),
  _Preset('Sunset', Icons.wb_twilight, (s) {
    s.setThemeMode(ThemeMode.dark);
    s.accentColor = const Color(0xFFFF6E40);
    s.amoledBlack = true;
    s.backgroundStyle = 3;
    s.backgroundDim = 0.55;
    s.glassEnabled = true;
    s.glassBlur = 26;
    s.glassOpacity = 0.25;
  }),
  _Preset('Ocean', Icons.waves, (s) {
    s.setThemeMode(ThemeMode.dark);
    s.accentColor = const Color(0xFF00B8D4);
    s.amoledBlack = false;
    s.backgroundStyle = 2;
    s.backgroundAnimated = true;
    s.backgroundDim = 0.5;
    s.glassEnabled = true;
    s.glassBlur = 20;
    s.glassOpacity = 0.18;
  }),
  _Preset('Forest', Icons.park_outlined, (s) {
    s.setThemeMode(ThemeMode.dark);
    s.accentColor = const Color(0xFF66BB6A);
    s.amoledBlack = false;
    s.backgroundStyle = 1;
    s.glassEnabled = true;
    s.glassBlur = 16;
    s.glassOpacity = 0.22;
  }),
  _Preset('Rose', Icons.local_florist_outlined, (s) {
    s.setThemeMode(ThemeMode.light);
    s.accentColor = const Color(0xFFEC407A);
    s.backgroundStyle = 1;
    s.glassEnabled = true;
    s.glassBlur = 18;
    s.glassOpacity = 0.3;
  }),
  _Preset('Frost', Icons.ac_unit, (s) {
    s.setThemeMode(ThemeMode.light);
    s.accentColor = const Color(0xFF1E88E5);
    s.backgroundStyle = 2;
    s.backgroundAnimated = true;
    s.backgroundDim = 0.7;
    s.glassEnabled = true;
    s.glassBlur = 22;
    s.glassOpacity = 0.35;
  }),
  _Preset('Mono', Icons.contrast, (s) {
    s.setThemeMode(ThemeMode.dark);
    s.accentColor = null;
    s.amoledBlack = true;
    s.backgroundStyle = 0;
    s.glassEnabled = false;
  }),
];

/// Every look-and-feel option of the desktop app lives here.
class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  static const List<Color> _swatches = [
    Color(0xFFE53935), // red
    Color(0xFFFB8C00), // orange
    Color(0xFFFDD835), // yellow
    Color(0xFF43A047), // green
    Color(0xFF00ACC1), // teal
    Color(0xFF1E88E5), // blue
    Color(0xFF5E35B1), // violet
    Color(0xFFD81B60), // pink
    Color(0xFF8D6E63), // brown
    Color(0xFF607D8B), // slate
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsManager>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              const GroupTitle(title: 'Presets'),
              SettingEmptyTile(
                isFirst: true,
                isLast: true,
                leading: const Icon(Icons.auto_awesome_motion),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in _presets)
                      ActionChip(
                        avatar: Icon(p.icon, size: 18),
                        label: Text(p.name),
                        onPressed: () => p.apply(s),
                      ),
                  ],
                ),
              ),
              const GroupTitle(title: 'Theme'),
              SettingTile(
                title: 'Theme mode',
                leading: const Icon(Icons.dark_mode),
                isFirst: true,
                trailing: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.system, label: Text('System')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (v) => s.setThemeMode(v.first),
                ),
              ),
              SettingSwitchTile(
                title: 'AMOLED black',
                subtitle: 'Pure black surfaces in dark mode',
                leading: const Icon(Icons.mode_night_outlined),
                value: s.amoledBlack,
                onChanged: (v) => s.amoledBlack = v,
              ),
              SettingSwitchTile(
                title: 'Dynamic album colours',
                subtitle: 'The whole app takes its accent from the current cover art',
                leading: const Icon(Icons.album_outlined),
                value: s.artAccent,
                onChanged: (v) => s.artAccent = v,
              ),
              SettingSwitchTile(
                title: 'Use Windows accent colour',
                subtitle: 'Follow your system accent (overrides the colour below)',
                leading: const Icon(Icons.color_lens_outlined),
                isLast: true,
                value: s.dynamicColors,
                onChanged: (v) => s.dynamicColors = v,
              ),
              const GroupTitle(title: 'Accent colour'),
              SettingEmptyTile(
                isFirst: true,
                leading: const Icon(Icons.palette_outlined),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Swatch(
                      color: null,
                      selected: s.accentColor == null,
                      onTap: () => s.accentColor = null,
                    ),
                    for (final c in _swatches)
                      _Swatch(
                        color: c,
                        selected: s.accentColor?.value == c.value,
                        onTap: () => s.accentColor = c,
                      ),
                  ],
                ),
              ),
              SettingTile(
                title: 'Custom colour…',
                leading: const Icon(Icons.colorize_rounded),
                isLast: true,
                trailing: CircleAvatar(
                  radius: 14,
                  backgroundColor: s.accentColor ?? scheme.primary,
                ),
                onTap: () => Modals.showAccentSelector(context),
              ),
              const GroupTitle(title: 'Layout'),
              SettingTile(
                title: 'Sidebar',
                leading: const Icon(Icons.view_sidebar_outlined),
                isFirst: true,
                trailing: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Auto')),
                    ButtonSegment(value: 1, label: Text('Compact')),
                    ButtonSegment(value: 2, label: Text('Expanded')),
                  ],
                  selected: {s.sidebarStyle},
                  onSelectionChanged: (v) => s.sidebarStyle = v.first,
                ),
              ),
              SettingSlider(
                label: 'Text size  ${(s.textScale * 100).round()}%',
                icon: Icons.text_fields,
                value: s.textScale,
                min: 0.8,
                max: 1.4,
                divisions: 12,
                onChanged: (v) => s.textScale = v,
              ),
              SettingSlider(
                label: 'Corner roundness  ${s.cornerRadius.round()}',
                icon: Icons.rounded_corner,
                value: s.cornerRadius,
                min: 4,
                max: 32,
                divisions: 14,
                isLast: true,
                onChanged: (v) => s.cornerRadius = v,
              ),
              const GroupTitle(title: 'Background'),
              SettingTile(
                title: 'Style',
                leading: const Icon(Icons.wallpaper),
                isFirst: true,
                trailing: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Solid')),
                    ButtonSegment(value: 1, label: Text('Gradient')),
                    ButtonSegment(value: 2, label: Text('Aurora')),
                    ButtonSegment(value: 3, label: Text('Album art')),
                  ],
                  selected: {s.backgroundStyle},
                  onSelectionChanged: (v) => s.backgroundStyle = v.first,
                ),
              ),
              if (s.backgroundStyle == 2)
                SettingSwitchTile(
                  title: 'Animate aurora',
                  leading: const Icon(Icons.animation),
                  value: s.backgroundAnimated,
                  onChanged: (v) => s.backgroundAnimated = v,
                ),
              SettingSlider(
                label: 'Background dimming  ${(s.backgroundDim * 100).round()}%',
                icon: Icons.brightness_6_outlined,
                value: s.backgroundDim,
                min: 0.2,
                max: 0.95,
                divisions: 15,
                isLast: true,
                onChanged: (v) => s.backgroundDim = v,
              ),
              const GroupTitle(title: 'Liquid glass'),
              SettingSwitchTile(
                title: 'Glass panels',
                subtitle: 'Frosted, blurred sidebar, player bar and cards',
                leading: const Icon(Icons.blur_on),
                isFirst: true,
                isLast: !s.glassEnabled,
                value: s.glassEnabled,
                onChanged: (v) => s.glassEnabled = v,
              ),
              if (s.glassEnabled) ...[
                SettingSlider(
                  label: 'Blur strength  ${s.glassBlur.round()}',
                  icon: Icons.lens_blur,
                  value: s.glassBlur,
                  min: 0,
                  max: 50,
                  divisions: 25,
                  onChanged: (v) => s.glassBlur = v,
                ),
                SettingSlider(
                  label: 'Tint strength  ${(s.glassOpacity * 100).round()}%',
                  icon: Icons.opacity,
                  value: s.glassOpacity,
                  min: 0.02,
                  max: 0.7,
                  divisions: 34,
                  isLast: true,
                  onChanged: (v) => s.glassOpacity = v,
                ),
              ],
              const GroupTitle(title: 'Typography'),
              SettingTile(
                title: 'Font',
                subtitle: 'Fonts download on first use (needs internet)',
                leading: const Icon(Icons.font_download_outlined),
                isFirst: true,
                trailing: DropdownButton<String>(
                  value: AppFonts.families.contains(s.fontFamily)
                      ? s.fontFamily
                      : AppFonts.families.first,
                  underline: const SizedBox(),
                  items: [
                    for (final f in AppFonts.families)
                      DropdownMenuItem(value: f, child: Text(f)),
                  ],
                  onChanged: (v) {
                    if (v != null) s.fontFamily = v;
                  },
                ),
              ),
              SettingSlider(
                label: 'Letter spacing  ${s.letterSpacing.toStringAsFixed(1)}',
                icon: Icons.space_bar,
                value: s.letterSpacing,
                min: -1,
                max: 4,
                divisions: 50,
                onChanged: (v) => s.letterSpacing = double.parse(v.toStringAsFixed(1)),
              ),
              SettingSlider(
                label: 'Word spacing  ${s.wordSpacing.toStringAsFixed(1)}',
                icon: Icons.text_format,
                value: s.wordSpacing,
                min: 0,
                max: 12,
                divisions: 24,
                isLast: true,
                onChanged: (v) => s.wordSpacing = double.parse(v.toStringAsFixed(1)),
              ),
              if (Platform.isWindows) ...[
                const GroupTitle(title: 'Window'),
                SettingTile(
                  title: 'Window material',
                  subtitle:
                      'Mica / Tabbed need Windows 11, Acrylic works on Windows 10+',
                  leading: const Icon(Icons.window_outlined),
                  isFirst: true,
                  isLast: true,
                  trailing: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 0, label: Text('None')),
                      ButtonSegment(value: 1, label: Text('Mica')),
                      ButtonSegment(value: 2, label: Text('Acrylic')),
                      ButtonSegment(value: 3, label: Text('Tabbed')),
                    ],
                    selected: {s.windowMaterial},
                    onSelectionChanged: (v) => s.windowMaterial = v.first,
                  ),
                ),
              ],
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
                const GroupTitle(title: 'Keyboard'),
                SettingSwitchTile(
                  title: 'Keyboard shortcuts',
                  subtitle:
                      'Space play/pause · ← → seek 5 s · Ctrl+← → previous/next · media keys',
                  leading: const Icon(Icons.keyboard_outlined),
                  isFirst: true,
                  isLast: true,
                  value: s.keyboardShortcuts,
                  onChanged: (v) => s.keyboardShortcuts = v,
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: s.resetAppearance,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset appearance to defaults'),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, this.onTap});
  final Color? color; // null = default monochrome
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          gradient: color == null
              ? const LinearGradient(
                  colors: [Colors.black, Colors.white],
                  stops: [0.5, 0.5],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(Icons.check,
                size: 18,
                color: color == null
                    ? Colors.grey
                    : (ThemeData.estimateBrightnessForColor(color!) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black))
            : null,
      ),
    );
  }
}
