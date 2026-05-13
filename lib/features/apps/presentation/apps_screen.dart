import 'package:flutter/material.dart';

import '../../../ui/input/contained_directional_focus.dart';
import '../domain/launcher_app.dart';
import 'widgets/app_grid.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({
    required this.appsFuture,
    required this.onReload,
    required this.emptyTitle,
    required this.active,
    super.key,
  });

  final Future<List<LauncherApp>> appsFuture;
  final VoidCallback onReload;
  final String emptyTitle;
  final bool active;

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  final FocusNode _messageActionFocusNode = FocusNode(
    debugLabel: 'Apps message action',
  );

  @override
  void initState() {
    super.initState();
    _focusMessageActionIfActive();
  }

  @override
  void didUpdateWidget(AppsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _focusMessageActionIfActive();
    }
  }

  @override
  void dispose() {
    _messageActionFocusNode.dispose();
    super.dispose();
  }

  void _focusMessageActionIfActive() {
    if (!widget.active) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active) {
        _messageActionFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContainedDirectionalFocus(
      child: FutureBuilder<List<LauncherApp>>(
        future: widget.appsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            _focusMessageActionIfActive();
            return _AppsMessage(
              icon: Icons.error_outline,
              title: 'Nie udało się wczytać aplikacji',
              action: IconButton(
                focusNode: _messageActionFocusNode,
                tooltip: 'Odśwież',
                onPressed: widget.onReload,
                icon: const Icon(Icons.refresh),
              ),
            );
          }

          final apps = snapshot.data ?? const [];
          if (apps.isEmpty) {
            _focusMessageActionIfActive();
            return _AppsMessage(
              icon: Icons.apps_outlined,
              title: widget.emptyTitle,
              action: IconButton(
                focusNode: _messageActionFocusNode,
                tooltip: 'Odśwież',
                onPressed: widget.onReload,
                icon: const Icon(Icons.refresh),
              ),
            );
          }

          return AppGrid(apps: apps, active: widget.active);
        },
      ),
    );
  }
}

class _AppsMessage extends StatelessWidget {
  const _AppsMessage({
    required this.icon,
    required this.title,
    required this.action,
  });

  final IconData icon;
  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52),
          const SizedBox(height: 14),
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 10),
          action,
        ],
      ),
    );
  }
}
