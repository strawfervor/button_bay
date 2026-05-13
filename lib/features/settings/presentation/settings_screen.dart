import 'dart:io';

import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.appsDirectoryPath,
    required this.onAppsDirectoryChanged,
    this.active = false,
    super.key,
  });

  final String? appsDirectoryPath;
  final ValueChanged<String> onAppsDirectoryChanged;
  final bool active;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FocusNode _chooseFolderFocusNode = FocusNode(
    debugLabel: 'Choose apps folder',
  );

  @override
  void initState() {
    super.initState();
    _focusChooseFolderIfActive();
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _focusChooseFolderIfActive();
    }
  }

  @override
  void dispose() {
    _chooseFolderFocusNode.dispose();
    super.dispose();
  }

  void _focusChooseFolderIfActive() {
    if (!widget.active) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active) {
        _chooseFolderFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPath = widget.appsDirectoryPath;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Settings', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 22),
              Text('My apps location', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.52,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Text(
                    currentPath ?? 'No folder selected',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: currentPath == null
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: _SettingsButton(
                  autofocus: widget.active,
                  focusNode: _chooseFolderFocusNode,
                  icon: Icons.folder_open,
                  label: currentPath == null
                      ? 'Choose folder'
                      : 'Change folder',
                  onPressed: () => _chooseFolder(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseFolder(BuildContext context) async {
    final selectedPath = await showDialog<String>(
      context: context,
      builder: (context) {
        return DirectoryPickerDialog(initialPath: widget.appsDirectoryPath);
      },
    );

    if (selectedPath == null || !context.mounted) {
      return;
    }

    widget.onAppsDirectoryChanged(selectedPath);
  }
}

class DirectoryPickerDialog extends StatefulWidget {
  const DirectoryPickerDialog({this.initialPath, super.key});

  final String? initialPath;

  @override
  State<DirectoryPickerDialog> createState() => _DirectoryPickerDialogState();
}

class _DirectoryPickerDialogState extends State<DirectoryPickerDialog> {
  late Directory _currentDirectory;

  @override
  void initState() {
    super.initState();
    _currentDirectory = _initialDirectory();
  }

  Directory _initialDirectory() {
    final initialPath = widget.initialPath;
    if (initialPath != null) {
      final directory = Directory(initialPath);
      if (directory.existsSync()) {
        return directory;
      }
    }

    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && Directory(home).existsSync()) {
      return Directory(home);
    }

    return Directory.current;
  }

  List<Directory> _childDirectories() {
    try {
      final directories = _currentDirectory
          .listSync(followLinks: false)
          .whereType<Directory>()
          .toList();
      directories.sort(
        (a, b) => _basename(
          a.path,
        ).toLowerCase().compareTo(_basename(b.path).toLowerCase()),
      );
      return directories;
    } on Object {
      return const [];
    }
  }

  void _open(Directory directory) {
    setState(() {
      _currentDirectory = directory;
    });
  }

  void _openParent() {
    final parent = _currentDirectory.parent;
    if (parent.path == _currentDirectory.path) {
      return;
    }
    _open(parent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final directories = _childDirectories();

    return AlertDialog(
      title: const Text('Choose apps folder'),
      content: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _currentDirectory.path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SettingsButton(
                  autofocus: true,
                  icon: Icons.check,
                  label: 'Use this folder',
                  onPressed: () =>
                      Navigator.of(context).pop(_currentDirectory.path),
                ),
                _SettingsButton(
                  icon: Icons.arrow_upward,
                  label: 'Up',
                  onPressed: _openParent,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: directories.isEmpty
                  ? Center(
                      child: Text(
                        'No subfolders',
                        style: theme.textTheme.titleMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: directories.length,
                      itemBuilder: (context, index) {
                        final directory = directories[index];
                        return _DirectoryRow(
                          directory: directory,
                          onOpen: () => _open(directory),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _DirectoryRow extends StatelessWidget {
  const _DirectoryRow({required this.directory, required this.onOpen});

  final Directory directory;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Actions(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onOpen();
            return null;
          },
        ),
      },
      child: Focus(
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return Material(
              color: focused
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.72)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                canRequestFocus: false,
                onTap: onOpen,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder,
                        color: focused
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _basename(directory.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: focused
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
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
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
    this.focusNode,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      autofocus: autofocus,
      focusNode: focusNode,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final trimmed = normalized.endsWith('/') && normalized.length > 1
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
  final separator = trimmed.lastIndexOf('/');
  return separator == -1 ? trimmed : trimmed.substring(separator + 1);
}
