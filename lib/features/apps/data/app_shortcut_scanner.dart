import 'dart:convert';
import 'dart:io';

import '../domain/launcher_app.dart';

class AppShortcutScanner {
  const AppShortcutScanner();

  Future<List<LauncherApp>> scan({String? directoryPath}) async {
    final selectedDirectory = _directoryFromPath(directoryPath);
    if (Platform.isWindows) {
      return _scanWindows(selectedDirectory);
    }

    if (Platform.isLinux) {
      return _scanLinux(selectedDirectory);
    }

    return const [];
  }

  Directory? _directoryFromPath(String? path) {
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    final directory = Directory(path);
    return directory.existsSync() ? directory : null;
  }

  Future<List<LauncherApp>> _scanLinux(Directory? selectedDirectory) async {
    final files = <File>[];
    for (final directory in _linuxShortcutDirectories(selectedDirectory)) {
      if (!directory.existsSync()) {
        continue;
      }
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.desktop')) {
          files.add(entity);
        }
      }
    }

    final iconIndex = _LinuxIconIndex(_linuxIconRoots())..build();
    final apps = <LauncherApp>[];
    final seen = <String>{};
    for (final file in files) {
      final app = await _parseDesktopFile(file, iconIndex);
      if (app == null || !seen.add(app.id)) {
        continue;
      }
      apps.add(app);
    }

    apps.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return apps;
  }

  List<Directory> _linuxShortcutDirectories(Directory? selectedDirectory) {
    if (selectedDirectory != null) {
      return [selectedDirectory];
    }

    final home = Platform.environment['HOME'];
    return [
      Directory('/usr/share/applications'),
      if (home != null) Directory('$home/.local/share/applications'),
      Directory('/var/lib/flatpak/exports/share/applications'),
      if (home != null)
        Directory('$home/.local/share/flatpak/exports/share/applications'),
    ];
  }

  List<Directory> _linuxIconRoots() {
    final home = Platform.environment['HOME'];
    return [
      if (home != null) Directory('$home/.local/share/icons'),
      if (home != null) Directory('$home/.icons'),
      Directory('/usr/share/icons'),
      Directory('/usr/share/pixmaps'),
      Directory('/var/lib/flatpak/exports/share/icons'),
      if (home != null)
        Directory('$home/.local/share/flatpak/exports/share/icons'),
    ];
  }

  Future<LauncherApp?> _parseDesktopFile(
    File file,
    _LinuxIconIndex iconIndex,
  ) async {
    final lines = await file.readAsLines();
    var inDesktopEntry = false;
    final values = <String, String>{};

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      if (line.startsWith('[') && line.endsWith(']')) {
        inDesktopEntry = line == '[Desktop Entry]';
        continue;
      }

      if (!inDesktopEntry) {
        continue;
      }

      final separator = line.indexOf('=');
      if (separator <= 0) {
        continue;
      }

      final key = line.substring(0, separator);
      final value = line.substring(separator + 1);
      values[key] = value;
    }

    if (values['Type'] != null && values['Type'] != 'Application') {
      return null;
    }
    if (_isTruthy(values['Hidden']) || _isTruthy(values['NoDisplay'])) {
      return null;
    }

    final title = values['Name'];
    if (title == null || title.trim().isEmpty) {
      return null;
    }

    final icon = values['Icon'];
    return LauncherApp(
      id: file.path,
      title: title.trim(),
      shortcutPath: file.path,
      command: values['Exec'],
      iconPath: iconIndex.resolve(icon),
    );
  }

  bool _isTruthy(String? value) => value?.toLowerCase() == 'true';

  Future<List<LauncherApp>> _scanWindows(Directory? selectedDirectory) async {
    final files = <File>[];
    for (final directory in _windowsShortcutDirectories(selectedDirectory)) {
      if (!directory.existsSync()) {
        continue;
      }
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.lnk')) {
          files.add(entity);
        }
      }
    }

    final apps = <LauncherApp>[];
    final seen = <String>{};
    for (final file in files) {
      final app = await _parseWindowsShortcut(file);
      if (app == null || !seen.add(app.shortcutPath.toLowerCase())) {
        continue;
      }
      apps.add(app);
    }

    apps.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return apps;
  }

  List<Directory> _windowsShortcutDirectories(Directory? selectedDirectory) {
    if (selectedDirectory != null) {
      return [selectedDirectory];
    }

    final programData = Platform.environment['ProgramData'];
    final appData = Platform.environment['APPDATA'];
    final publicProfile = Platform.environment['PUBLIC'];
    final userProfile = Platform.environment['USERPROFILE'];

    return [
      if (programData != null)
        Directory('$programData\\Microsoft\\Windows\\Start Menu\\Programs'),
      if (publicProfile != null) Directory('$publicProfile\\Desktop'),
      if (appData != null)
        Directory('$appData\\Microsoft\\Windows\\Start Menu\\Programs'),
      if (userProfile != null) Directory('$userProfile\\Desktop'),
    ];
  }

  Future<LauncherApp?> _parseWindowsShortcut(File file) async {
    final script = '''
\$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut(\$args[0])
[PSCustomObject]@{
  target = \$shortcut.TargetPath
  icon = \$shortcut.IconLocation
} | ConvertTo-Json -Compress
''';

    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        script,
        file.path,
      ]).timeout(const Duration(seconds: 2));
      if (result.exitCode != 0) {
        return _windowsShortcutFallback(file);
      }

      final decoded =
          jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
      final iconPath = _cleanWindowsIconPath(decoded['icon'] as String?);
      return LauncherApp(
        id: file.path,
        title: _shortcutTitle(file),
        shortcutPath: file.path,
        command: decoded['target'] as String?,
        iconPath: iconPath,
      );
    } on Object {
      return _windowsShortcutFallback(file);
    }
  }

  LauncherApp _windowsShortcutFallback(File file) {
    return LauncherApp(
      id: file.path,
      title: _shortcutTitle(file),
      shortcutPath: file.path,
    );
  }

  String _shortcutTitle(File file) {
    final name = file.uri.pathSegments.last;
    return name.replaceFirst(RegExp(r'\.lnk$', caseSensitive: false), '');
  }

  String? _cleanWindowsIconPath(String? iconLocation) {
    if (iconLocation == null || iconLocation.trim().isEmpty) {
      return null;
    }

    final path = iconLocation.split(',').first.trim();
    if (path.isEmpty || !File(path).existsSync()) {
      return null;
    }
    return path;
  }
}

class _LinuxIconIndex {
  _LinuxIconIndex(this.roots);

  static const _extensions = {'png', 'webp', 'jpg', 'jpeg', 'bmp', 'ico'};

  final List<Directory> roots;
  final Map<String, _IconCandidate> _icons = {};
  bool _built = false;

  void build() {
    if (_built) {
      return;
    }
    _built = true;

    for (final root in roots) {
      if (!root.existsSync()) {
        continue;
      }

      try {
        for (final entity in root.listSync(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is! File) {
            continue;
          }

          final segments = entity.uri.pathSegments;
          if (segments.isEmpty) {
            continue;
          }

          final fileName = segments.last;
          final extensionSeparator = fileName.lastIndexOf('.');
          if (extensionSeparator <= 0) {
            continue;
          }

          final extension = fileName
              .substring(extensionSeparator + 1)
              .toLowerCase();
          if (!_extensions.contains(extension)) {
            continue;
          }

          final iconName = fileName
              .substring(0, extensionSeparator)
              .toLowerCase();
          final candidate = _IconCandidate(entity.path);
          final current = _icons[iconName];
          if (current == null || candidate.score > current.score) {
            _icons[iconName] = candidate;
          }
        }
      } on FileSystemException {
        continue;
      }
    }
  }

  String? resolve(String? icon) {
    if (icon == null || icon.trim().isEmpty) {
      return null;
    }

    final cleanedIcon = icon.trim();
    if (cleanedIcon.startsWith('/')) {
      return File(cleanedIcon).existsSync() ? cleanedIcon : null;
    }

    return _icons[cleanedIcon.toLowerCase()]?.path;
  }
}

class _IconCandidate {
  _IconCandidate(this.path) : score = _score(path);

  final String path;
  final int score;

  static int _score(String path) {
    if (path.contains('/512x512/')) return 7;
    if (path.contains('/256x256/')) return 6;
    if (path.contains('/128x128/')) return 5;
    if (path.contains('/96x96/')) return 4;
    if (path.contains('/64x64/')) return 3;
    if (path.contains('/48x48/')) return 2;
    if (path.contains('/32x32/')) return 1;
    return 0;
  }
}
