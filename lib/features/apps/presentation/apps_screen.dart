import 'package:flutter/material.dart';

import '../domain/launcher_app.dart';
import 'widgets/app_grid.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({
    required this.appsFuture,
    required this.onReload,
    required this.emptyTitle,
    super.key,
  });

  final Future<List<LauncherApp>> appsFuture;
  final VoidCallback onReload;
  final String emptyTitle;

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LauncherApp>>(
      future: widget.appsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _AppsMessage(
            icon: Icons.error_outline,
            title: 'Nie udało się wczytać aplikacji',
            action: IconButton(
              tooltip: 'Odśwież',
              onPressed: widget.onReload,
              icon: const Icon(Icons.refresh),
            ),
          );
        }

        final apps = snapshot.data ?? const [];
        if (apps.isEmpty) {
          return _AppsMessage(
            icon: Icons.apps_outlined,
            title: widget.emptyTitle,
            action: IconButton(
              tooltip: 'Odśwież',
              onPressed: widget.onReload,
              icon: const Icon(Icons.refresh),
            ),
          );
        }

        return AppGrid(apps: apps);
      },
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
