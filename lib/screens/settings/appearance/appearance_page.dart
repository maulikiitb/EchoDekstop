import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/settings_manager.dart';
import '../../../utils/bottom_modals.dart';
import '../widgets/setting_item.dart';

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
                title: 'Gradient background',
                subtitle: 'Soft accent-tinted gradient behind every page',
                leading: const Icon(Icons.gradient),
                value: s.gradientBackground,
                onChanged: (v) => s.gradientBackground = v,
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
              SettingEmptyTile(
                leading: const Icon(Icons.text_fields),
                child: _SliderRow(
                  label: 'Text size  ${(s.textScale * 100).round()}%',
                  value: s.textScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 12,
                  onChanged: (v) => s.textScale = v,
                ),
              ),
              SettingEmptyTile(
                isLast: true,
                leading: const Icon(Icons.rounded_corner),
                child: _SliderRow(
                  label: 'Corner roundness  ${s.cornerRadius.round()}',
                  value: s.cornerRadius,
                  min: 4,
                  max: 32,
                  divisions: 14,
                  onChanged: (v) => s.cornerRadius = v,
                ),
              ),
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

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });
  final String label;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
