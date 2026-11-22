import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../services/settings_manager.dart';
import '../../utils/glass.dart';
import 'widgets/bottom_player.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey('AppShell'));
  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final settings = context.watch<SettingsManager>();
    final scheme = Theme.of(context).colorScheme;
    final bool wide = screenWidth >= 450;

    // 0 = auto, 1 = compact (icons only), 2 = expanded (icons + labels)
    final bool extended = settings.sidebarStyle == 2 ||
        (settings.sidebarStyle == 0 && screenWidth >= 1100);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Row(
            children: [
              if (wide)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                    child: Glass(
                      radius: settings.cornerRadius + 4,
                      child: NavigationRail(
                    extended: extended,
                    labelType: extended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    backgroundColor: Colors.transparent,
                    groupAlignment: 0.0,
                    minExtendedWidth: 200,
                    destinations: [
                      NavigationRailDestination(
                        selectedIcon: const Icon(CupertinoIcons.music_house_fill),
                        icon: const Icon(CupertinoIcons.music_house),
                        label: Text(S.of(context).Home),
                      ),
                      NavigationRailDestination(
                        selectedIcon: const Icon(CupertinoIcons.search),
                        icon: const Icon(CupertinoIcons.search),
                        label: Text(S.of(context).Search_Echo),
                      ),
                      NavigationRailDestination(
                        selectedIcon: const Icon(Icons.library_music),
                        icon: const Icon(Icons.library_music_outlined),
                        label: Text(S.of(context).Saved),
                      ),
                      NavigationRailDestination(
                        selectedIcon: const Icon(CupertinoIcons.gear_alt_fill),
                        icon: const Icon(CupertinoIcons.gear_alt),
                        label: Text(S.of(context).Settings),
                      ),
                    ],
                    selectedIndex: widget.navigationShell.currentIndex,
                    onDestinationSelected: _goBranch,
                      ),
                    ),
                  ),
                ),
              Expanded(child: widget.navigationShell),
            ],
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: !wide
          ? NavigationBar(
              selectedIndex: widget.navigationShell.currentIndex,
              destinations: [
                NavigationDestination(
                  selectedIcon: const Icon(CupertinoIcons.music_house_fill),
                  icon: const Icon(CupertinoIcons.music_house),
                  label: S.of(context).Home,
                ),
                NavigationDestination(
                  selectedIcon: const Icon(CupertinoIcons.search),
                  icon: const Icon(CupertinoIcons.search),
                  label: S.of(context).Search_Echo,
                ),
                NavigationDestination(
                  selectedIcon: const Icon(Icons.library_music),
                  icon: const Icon(Icons.library_music_outlined),
                  label: S.of(context).Saved,
                ),
                NavigationDestination(
                  selectedIcon: const Icon(CupertinoIcons.settings_solid),
                  icon: const Icon(CupertinoIcons.settings),
                  label: S.of(context).Settings,
                ),
              ],
              backgroundColor: scheme.surfaceContainerLow,
              onDestinationSelected: _goBranch,
            )
          : null,
    );
  }
}
