import 'package:flutter/material.dart';

import '../../../../ui/input/contained_directional_focus.dart';

class SearchKeyboard extends StatelessWidget {
  const SearchKeyboard({
    required this.query,
    required this.active,
    required this.onLetter,
    required this.onSpace,
    required this.onBackspace,
    required this.onSearch,
    super.key,
  });

  final String query;
  final bool active;
  final ValueChanged<String> onLetter;
  final VoidCallback onSpace;
  final VoidCallback onBackspace;
  final VoidCallback onSearch;

  static const _rows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  @override
  Widget build(BuildContext context) {
    return _SearchKeyboardBody(
      query: query,
      active: active,
      onLetter: onLetter,
      onSpace: onSpace,
      onBackspace: onBackspace,
      onSearch: onSearch,
    );
  }
}

class _SearchKeyboardBody extends StatefulWidget {
  const _SearchKeyboardBody({
    required this.query,
    required this.active,
    required this.onLetter,
    required this.onSpace,
    required this.onBackspace,
    required this.onSearch,
  });

  final String query;
  final bool active;
  final ValueChanged<String> onLetter;
  final VoidCallback onSpace;
  final VoidCallback onBackspace;
  final VoidCallback onSearch;

  @override
  State<_SearchKeyboardBody> createState() => _SearchKeyboardBodyState();
}

class _SearchKeyboardBodyState extends State<_SearchKeyboardBody> {
  final FocusNode _firstKeyFocusNode = FocusNode(debugLabel: 'Search key Q');

  @override
  void initState() {
    super.initState();
    _focusFirstKeyIfActive();
  }

  @override
  void didUpdateWidget(_SearchKeyboardBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _focusFirstKeyIfActive();
    }
  }

  @override
  void dispose() {
    _firstKeyFocusNode.dispose();
    super.dispose();
  }

  void _focusFirstKeyIfActive() {
    if (!widget.active) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active) {
        _firstKeyFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContainedDirectionalFocus(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 58,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.54,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.45,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.query.isEmpty ? 'Search all apps' : widget.query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: widget.query.isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final row in SearchKeyboard._rows) ...[
                        _KeyboardRow(
                          children: [
                            for (final letter in row)
                              _KeyboardKey(
                                label: letter,
                                focusNode: letter == 'Q'
                                    ? _firstKeyFocusNode
                                    : null,
                                onPressed: () => widget.onLetter(letter),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      _KeyboardRow(
                        children: [
                          _KeyboardKey(
                            label: 'Space',
                            flex: 3,
                            onPressed: widget.onSpace,
                          ),
                          _KeyboardKey(
                            label: 'Back',
                            icon: Icons.backspace_outlined,
                            semanticLabel: 'Backspace',
                            onPressed: widget.onBackspace,
                          ),
                          _KeyboardKey(
                            icon: Icons.search,
                            semanticLabel: 'Search',
                            onPressed: widget.onSearch,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyboardRow extends StatelessWidget {
  const _KeyboardRow({required this.children});

  final List<_KeyboardKey> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Flexible(flex: children[index].flex, child: children[index]),
          if (index < children.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _KeyboardKey extends StatelessWidget {
  const _KeyboardKey({
    this.label,
    this.icon,
    this.semanticLabel,
    this.focusNode,
    this.flex = 1,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final int flex;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onPressed();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: focusNode,
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasFocus;
              return SizedBox(
                height: 52,
                child: Material(
                  color: focused
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPressed,
                    child: Center(
                      child: icon == null
                          ? Text(
                              label ?? '',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: focused
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : Icon(
                              icon,
                              color: focused
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
