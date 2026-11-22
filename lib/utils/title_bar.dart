import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Custom Windows title bar (drag area + minimise / maximise / close).
class AppTitleBar extends StatefulWidget {
  const AppTitleBar({super.key});

  @override
  State<AppTitleBar> createState() => _AppTitleBarState();
}

class _AppTitleBarState extends State<AppTitleBar> with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((v) {
      if (mounted) setState(() => _maximized = v);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: 38,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => windowManager.startDragging(),
                onDoubleTap: _toggleMaximize,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Row(
                    children: [
                      Image.asset(
                        'icons/Echo_nobg.png',
                        width: 18,
                        height: 18,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.music_note, size: 18, color: scheme.onSurface),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Echo Music',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _CaptionButton(
              icon: Icons.remove,
              onTap: () => windowManager.minimize(),
            ),
            _CaptionButton(
              icon: _maximized ? Icons.filter_none : Icons.crop_square,
              iconSize: _maximized ? 13 : 15,
              onTap: _toggleMaximize,
            ),
            _CaptionButton(
              icon: Icons.close,
              danger: true,
              onTap: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.icon,
    required this.onTap,
    this.danger = false,
    this.iconSize = 16,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  final double iconSize;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg = _hover
        ? (widget.danger
            ? const Color(0xFFE81123)
            : scheme.onSurface.withValues(alpha: 0.12))
        : Colors.transparent;
    final Color fg =
        _hover && widget.danger ? Colors.white : scheme.onSurface;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 38,
          color: bg,
          alignment: Alignment.center,
          child: Icon(widget.icon, size: widget.iconSize, color: fg),
        ),
      ),
    );
  }
}
