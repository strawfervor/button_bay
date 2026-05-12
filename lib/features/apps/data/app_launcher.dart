import 'dart:io';

import '../domain/launcher_app.dart';

class AppLauncher {
  const AppLauncher();

  Future<void> launch(LauncherApp app) async {
    if (Platform.isWindows) {
      await _launchWindows(app);
      return;
    }

    if (Platform.isLinux) {
      await _launchLinux(app);
      return;
    }

    throw UnsupportedError('Launching apps is not supported here.');
  }

  Future<void> _launchWindows(LauncherApp app) async {
    await Process.start('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      'Start-Process -LiteralPath \$args[0]',
      app.shortcutPath,
    ], mode: ProcessStartMode.detached);
  }

  Future<void> _launchLinux(LauncherApp app) async {
    final command = app.command;
    if (command == null || command.trim().isEmpty) {
      throw StateError('Missing Exec command for ${app.title}.');
    }

    await Process.start('/bin/sh', [
      '-c',
      _cleanDesktopExec(command),
    ], mode: ProcessStartMode.detached);
  }

  String _cleanDesktopExec(String command) {
    return command
        .replaceAll('%%', '%')
        .replaceAll(RegExp(r'%[fFuUdDnNickvm]'), '')
        .trim();
  }
}
