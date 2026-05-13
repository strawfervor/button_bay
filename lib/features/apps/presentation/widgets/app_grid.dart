import 'package:flutter/material.dart';

import '../../../../ui/input/contained_directional_focus.dart';
import '../../domain/launcher_app.dart';
import 'app_tile.dart';

class AppGrid extends StatefulWidget {
  const AppGrid({required this.apps, required this.active, super.key});

  final List<LauncherApp> apps;
  final bool active;

  @override
  State<AppGrid> createState() => _AppGridState();
}

class _AppGridState extends State<AppGrid> {
  final FocusNode _firstTileFocusNode = FocusNode(debugLabel: 'First app tile');

  @override
  void initState() {
    super.initState();
    _focusFirstTileIfActive();
  }

  @override
  void didUpdateWidget(AppGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.active && !oldWidget.active) ||
        (widget.active && widget.apps != oldWidget.apps)) {
      _focusFirstTileIfActive();
    }
  }

  @override
  void dispose() {
    _firstTileFocusNode.dispose();
    super.dispose();
  }

  void _focusFirstTileIfActive() {
    if (!widget.active || widget.apps.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active && widget.apps.isNotEmpty) {
        _firstTileFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContainedDirectionalFocus(
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 172,
          mainAxisExtent: 164,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
        ),
        itemCount: widget.apps.length,
        itemBuilder: (context, index) {
          return AppTile(
            app: widget.apps[index],
            autofocus: widget.active && index == 0,
            focusNode: index == 0 ? _firstTileFocusNode : null,
          );
        },
      ),
    );
  }
}
