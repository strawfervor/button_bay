import 'dart:io';

import 'package:hive_ce/hive.dart';

class AppSettingsStore {
  AppSettingsStore._(this._box);

  static const _boxName = 'app_settings';
  static const _appsDirectoryKey = 'apps_directory';

  final Box<dynamic> _box;

  static Future<AppSettingsStore> open() async {
    ensureButtonBaySettingsStorageInitialized();
    final box = await Hive.openBox<dynamic>(_boxName);
    return AppSettingsStore._(box);
  }

  String? get appsDirectoryPath {
    final value = _box.get(_appsDirectoryKey);
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> setAppsDirectoryPath(String path) async {
    await _box.put(_appsDirectoryKey, path);
  }
}

void ensureButtonBaySettingsStorageInitialized() {
  if (_AppSettingsStorageState.initialized) {
    return;
  }

  final settingsPath = buttonBaySettingsPath();
  Directory(settingsPath).createSync(recursive: true);
  Hive.init(settingsPath);
  _AppSettingsStorageState.initialized = true;
}

class _AppSettingsStorageState {
  static bool initialized = false;
}

String buttonBaySettingsPath() {
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return '$appData\\ButtonBay';
    }
  }

  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return '$home/Library/Application Support/ButtonBay';
    }
  }

  final xdgConfigHome = Platform.environment['XDG_CONFIG_HOME'];
  if (xdgConfigHome != null && xdgConfigHome.isNotEmpty) {
    return '$xdgConfigHome/button_bay';
  }

  final home = Platform.environment['HOME'];
  if (home != null && home.isNotEmpty) {
    return '$home/.config/button_bay';
  }

  return '.button_bay';
}
