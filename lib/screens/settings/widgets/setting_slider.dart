import 'package:flutter/material.dart';

import 'setting_item.dart';

/// A settings card holding a labelled slider.
class SettingSlider extends StatelessWidget {
  const SettingSlider({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final IconData icon;
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final bool isFirst, isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SettingEmptyTile(
        isFirst: isFirst,
        isLast: isLast,
        leading: Icon(icon),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
