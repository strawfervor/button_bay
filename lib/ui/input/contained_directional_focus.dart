import 'package:flutter/material.dart';

class ContainedDirectionalFocus extends StatefulWidget {
  const ContainedDirectionalFocus({required this.child, super.key});

  final Widget child;

  @override
  State<ContainedDirectionalFocus> createState() =>
      _ContainedDirectionalFocusState();
}

class _ContainedDirectionalFocusState extends State<ContainedDirectionalFocus> {
  late final FocusScopeNode _scopeNode = FocusScopeNode(
    debugLabel: 'Contained directional focus',
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.stop,
  );

  @override
  void dispose() {
    _scopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope.withExternalFocusNode(
      focusScopeNode: _scopeNode,
      child: Actions(
        actions: {
          DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
            onInvoke: (intent) {
              final focusedNode = FocusManager.instance.primaryFocus;
              if (focusedNode == null || !_scopeNode.hasFocus) {
                return null;
              }

              final moved = focusedNode.focusInDirection(intent.direction);
              if ((!moved || !_scopeNode.hasFocus) &&
                  focusedNode.canRequestFocus) {
                focusedNode.requestFocus();
              }
              return null;
            },
          ),
        },
        child: widget.child,
      ),
    );
  }
}
