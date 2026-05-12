import 'dart:async';

import 'package:button_bay/features/apps/data/app_shortcut_scanner.dart';
import 'package:button_bay/features/apps/domain/launcher_app.dart';
import 'package:button_bay/features/apps/presentation/apps_screen.dart';
import 'package:button_bay/features/apps/presentation/search_screen.dart';
import 'package:button_bay/ui/input/app_intents.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<LauncherApp>> _appsFuture;
  StreamSubscription<GamepadEvent>? _gamepadSubscription;
  final Map<String, int> _lastGamepadActionAt = {};

  static const _tabs = [
    _ShellTab(label: 'All apps', icon: Icons.apps),
    _ShellTab(label: 'Search', icon: Icons.search),
    _ShellTab(label: 'Files', icon: Icons.folder),
  ];

  @override
  void initState() {
    super.initState();
    _appsFuture = const AppShortcutScanner().scan();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _gamepadSubscription = Gamepads.events.listen(_handleGamepadEvent);
  }

  @override
  void dispose() {
    _gamepadSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _reloadApps() {
    setState(() {
      _appsFuture = const AppShortcutScanner().scan();
    });
  }

  void _handleGamepadEvent(GamepadEvent event) {
    if (event.value < 0.75) {
      return;
    }

    final key = event.key.toLowerCase();
    if (_isPreviousTabKey(key)) {
      if (!_canRunGamepadAction('tab:$key', event.timestamp)) {
        return;
      }
      _selectRelativeTab(-1);
    } else if (_isNextTabKey(key)) {
      if (!_canRunGamepadAction('tab:$key', event.timestamp)) {
        return;
      }
      _selectRelativeTab(1);
    } else if (_isActivateKey(key)) {
      if (!_canRunGamepadAction('activate:$key', event.timestamp)) {
        return;
      }
      _invokeFocusedAction(const ActivateIntent());
    } else if (_isBackKey(key)) {
      if (!_canRunGamepadAction('back:$key', event.timestamp)) {
        return;
      }
      _invokeFocusedAction(const AppBackIntent());
    } else if (_directionForKey(key) case final direction?) {
      if (!_canRunGamepadAction('direction:$key', event.timestamp, 140)) {
        return;
      }
      _invokeFocusedAction(DirectionalFocusIntent(direction));
    }
  }

  bool _canRunGamepadAction(String key, int timestamp, [int cooldownMs = 240]) {
    final previous = _lastGamepadActionAt[key];
    if (previous != null && timestamp - previous < cooldownMs) {
      return false;
    }
    _lastGamepadActionAt[key] = timestamp;
    return true;
  }

  bool _isPreviousTabKey(String key) {
    return key.contains('leftshoulder') ||
        key.contains('left shoulder') ||
        key.contains('lefttrigger') ||
        key.contains('left trigger') ||
        key == 'l1' ||
        key == 'lb' ||
        key == 'lt';
  }

  bool _isNextTabKey(String key) {
    return key.contains('rightshoulder') ||
        key.contains('right shoulder') ||
        key.contains('righttrigger') ||
        key.contains('right trigger') ||
        key == 'r1' ||
        key == 'rb' ||
        key == 'rt';
  }

  bool _isActivateKey(String key) {
    return key == 'a' ||
        key == 'buttona' ||
        key == 'button a' ||
        key == 'button0' ||
        key == 'button 0' ||
        key.contains('south');
  }

  bool _isBackKey(String key) {
    return key == 'b' ||
        key == 'buttonb' ||
        key == 'button b' ||
        key == 'button1' ||
        key == 'button 1' ||
        key.contains('east');
  }

  TraversalDirection? _directionForKey(String key) {
    if (key == 'dpadup' ||
        key == 'dpad up' ||
        key == 'hatup' ||
        key == 'hat up' ||
        key == 'up') {
      return TraversalDirection.up;
    }
    if (key == 'dpaddown' ||
        key == 'dpad down' ||
        key == 'hatdown' ||
        key == 'hat down' ||
        key == 'down') {
      return TraversalDirection.down;
    }
    if (key == 'dpadleft' ||
        key == 'dpad left' ||
        key == 'hatleft' ||
        key == 'hat left' ||
        key == 'left') {
      return TraversalDirection.left;
    }
    if (key == 'dpadright' ||
        key == 'dpad right' ||
        key == 'hatright' ||
        key == 'hat right' ||
        key == 'right') {
      return TraversalDirection.right;
    }
    return null;
  }

  void _selectRelativeTab(int offset) {
    final nextIndex = (_tabController.index + offset) % _tabController.length;
    _tabController.animateTo(
      nextIndex < 0 ? _tabController.length - 1 : nextIndex,
      duration: Duration.zero,
    );
  }

  void _invokeFocusedAction(Intent intent) {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) {
      return;
    }

    Actions.maybeInvoke(context, intent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.tab): _NextTabIntent(),
        SingleActivator(LogicalKeyboardKey.tab, shift: true):
            _PreviousTabIntent(),
      },
      child: Actions(
        actions: {
          _NextTabIntent: CallbackAction<_NextTabIntent>(
            onInvoke: (_) {
              _selectRelativeTab(1);
              return null;
            },
          ),
          _PreviousTabIntent: CallbackAction<_PreviousTabIntent>(
            onInvoke: (_) {
              _selectRelativeTab(-1);
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        'ButtonBay',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 420,
                        child: TabBar(
                          controller: _tabController,
                          tabs: [
                            for (final tab in _tabs)
                              Tab(icon: Icon(tab.icon), text: tab.label),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final activeIndex = _tabController.index;
                      return IndexedStack(
                        index: activeIndex,
                        children: [
                          AppsScreen(
                            appsFuture: _appsFuture,
                            onReload: _reloadApps,
                          ),
                          SearchScreen(
                            appsFuture: _appsFuture,
                            active: activeIndex == 1,
                          ),
                          const _FileManagerPlaceholder(),
                        ],
                      );
                    },
                  ),
                ),
                const _ControlHintsBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextTabIntent extends Intent {
  const _NextTabIntent();
}

class _PreviousTabIntent extends Intent {
  const _PreviousTabIntent();
}

class _ShellTab {
  const _ShellTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _ControlHintsBar extends StatelessWidget {
  const _ControlHintsBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.45,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.62),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 9, 24, 10),
        child: Wrap(
          spacing: 18,
          runSpacing: 8,
          children: const [
            _ControlHint(keysLabel: 'Enter / A', actionLabel: 'Run'),
            _ControlHint(keysLabel: 'B / Backspace', actionLabel: 'Back'),
            _ControlHint(keysLabel: 'Tab / RT / RB', actionLabel: 'Change tab'),
          ],
        ),
      ),
    );
  }
}

class _ControlHint extends StatelessWidget {
  const _ControlHint({required this.keysLabel, required this.actionLabel});

  final String keysLabel;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 28,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            keysLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          actionLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FileManagerPlaceholder extends StatelessWidget {
  const _FileManagerPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_outlined, size: 56),
          const SizedBox(height: 14),
          Text('File manager', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
