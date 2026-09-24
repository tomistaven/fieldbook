import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Always-visible input for fast consecutive entry.
class QuickAddBar extends StatefulWidget {
  const QuickAddBar({
    super.key,
    required this.onAdd,
    this.buttonOnLeft = false,
  });

  final ValueChanged<String> onAdd;

  /// Puts the add button before the field, for one-handed use.
  final bool buttonOnLeft;

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.onAdd(name);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final field = Expanded(
      child: TextField(
        controller: _controller,
        maxLength: AppConstants.maxShoppingNameLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          hintText: 'Add item',
          counterText: '',
        ),
        // onEditingComplete (instead of onSubmitted) suppresses the default
        // unfocus, so the keyboard stays open between items.
        onEditingComplete: _add,
      ),
    );
    final button = IconButton(
      tooltip: 'Add',
      icon: const Icon(Icons.add_circle),
      onPressed: _add,
    );
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        // The icon button carries its own padding, so its side gets less.
                padding: widget.buttonOnLeft
            ? const EdgeInsets.fromLTRB(8, 8, 16, 8)
            : const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: widget.buttonOnLeft ? [button, field] : [field, button],
        ),
      ),
    );
  }
}