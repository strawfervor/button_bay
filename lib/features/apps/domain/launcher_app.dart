import 'dart:io';

class LauncherApp {
  const LauncherApp({
    required this.id,
    required this.title,
    required this.shortcutPath,
    this.command,
    this.iconPath,
  });

  final String id;
  final String title;
  final String shortcutPath;
  final String? command;
  final String? iconPath;

  bool get hasDisplayableIcon {
    final path = iconPath;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      return false;
    }

    final extension = path.split('.').last.toLowerCase();
    return extension == 'png' ||
        extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'gif' ||
        extension == 'webp' ||
        extension == 'bmp' ||
        extension == 'ico';
  }
}
