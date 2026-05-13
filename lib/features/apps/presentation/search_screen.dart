import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/input/app_intents.dart';
import '../domain/launcher_app.dart';
import 'widgets/app_grid.dart';
import 'widgets/search_keyboard.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    required this.appsFuture,
    required this.active,
    super.key,
  });

  final Future<List<LauncherApp>> appsFuture;
  final bool active;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  List<LauncherApp> _results = const [];
  bool _showResults = false;

  void _append(String value) {
    setState(() {
      _query += value;
    });
  }

  void _space() {
    if (_query.isEmpty || _query.endsWith(' ')) {
      return;
    }
    _append(' ');
  }

  void _backspace() {
    if (_query.isEmpty) {
      return;
    }
    setState(() {
      _query = _query.substring(0, _query.length - 1);
    });
  }

  void _handleBack() {
    if (_showResults) {
      setState(() {
        _showResults = false;
      });
      return;
    }
    _backspace();
  }

  Future<void> _search() async {
    final apps = await widget.appsFuture;
    final query = _query.trim().toLowerCase();
    setState(() {
      _results = query.isEmpty
          ? apps
          : apps
                .where((app) => app.title.toLowerCase().contains(query))
                .toList(growable: false);
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.backspace): AppBackIntent(),
      },
      child: Actions(
        actions: {
          AppBackIntent: CallbackAction<AppBackIntent>(
            onInvoke: (_) {
              _handleBack();
              return null;
            },
          ),
        },
        child: FutureBuilder<List<LauncherApp>>(
          future: widget.appsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const _SearchMessage(
                icon: Icons.error_outline,
                title: 'Nie udało się wczytać aplikacji',
              );
            }

            if (_showResults) {
              if (_results.isEmpty) {
                return const _SearchMessage(
                  icon: Icons.search_off,
                  title: 'Brak wyników',
                );
              }
              return AppGrid(apps: _results, active: widget.active);
            }

            return SearchKeyboard(
              query: _query,
              active: widget.active && !_showResults,
              onLetter: _append,
              onSpace: _space,
              onBackspace: _backspace,
              onSearch: _search,
            );
          },
        ),
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52),
          const SizedBox(height: 14),
          Text(title, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
