import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/app_launcher.dart';
import '../../domain/launcher_app.dart';

class AppTile extends StatelessWidget {
  const AppTile({required this.app, this.autofocus = false, super.key});

  final LauncherApp app;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Actions(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _launch(context);
            return null;
          },
        ),
      },
      child: Focus(
        autofocus: autofocus,
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return Material(
              color: focused
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.76)
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.54,
                    ),
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                canRequestFocus: false,
                onTap: () => _launch(context),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AppIcon(app: app),
                      const SizedBox(height: 12),
                      Text(
                        app.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          height: 1.12,
                          color: focused
                              ? theme.colorScheme.onPrimaryContainer
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _launch(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await const AppLauncher().launch(app);
    } on Object {
      messenger?.showSnackBar(
        SnackBar(content: Text('Nie udało się uruchomić: ${app.title}')),
      );
    }
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.app});

  final LauncherApp app;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (app.hasDisplayableIcon) {
      return SizedBox.square(
        dimension: 78,
        child: Image.file(
          File(app.iconPath!),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _FallbackIcon(colorScheme: colorScheme),
        ),
      );
    }

    return _FallbackIcon(colorScheme: colorScheme);
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.apps, color: colorScheme.onPrimaryContainer, size: 38),
    );
  }
}
