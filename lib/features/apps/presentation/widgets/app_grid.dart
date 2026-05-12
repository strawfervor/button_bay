import 'package:flutter/material.dart';

import '../../domain/launcher_app.dart';
import 'app_tile.dart';

class AppGrid extends StatelessWidget {
  const AppGrid({required this.apps, super.key});

  final List<LauncherApp> apps;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 172,
        mainAxisExtent: 164,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        return AppTile(app: apps[index], autofocus: index == 0);
      },
    );
  }
}
