import 'package:flutter/material.dart';

import '../../design_system/tokens.dart';

class AnswerTile extends StatefulWidget {
  const AnswerTile({
    super.key,
    required this.index,
    required this.text,
    required this.onPressed,
    this.correct = false,
    this.selected = false,
  });
  final int index;
  final String text;
  final VoidCallback? onPressed;
  final bool correct, selected;
  @override
  State<AnswerTile> createState() => _AnswerTileState();
}

class _AnswerTileState extends State<AnswerTile> {
  final _focus = FocusNode();
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.onPressed == null;
    final filled = locked && widget.correct;
    final background = filled ? GameColors.screenInk : GameColors.screen;
    final ink = filled ? GameColors.screen : GameColors.screenInk;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(color: GameColors.screenInk, offset: Offset(0, 3)),
          ],
        ),
        child: FilledButton(
          key: ValueKey('answer-${widget.index}'),
          focusNode: _focus,
          onPressed: widget.onPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(background),
            foregroundColor: WidgetStatePropertyAll(ink),
            minimumSize: const WidgetStatePropertyAll(Size(48, 88)),
            padding: const WidgetStatePropertyAll(EdgeInsets.all(16)),
            overlayColor: WidgetStatePropertyAll(
              GameColors.violet.withValues(alpha: 0.12),
            ),
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.focused)
                    ? GameColors.violet
                    : GameColors.screenInk,
                width:
                    states.contains(WidgetState.focused) ||
                        widget.selected ||
                        widget.correct
                    ? 3
                    : 1.5,
              ),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Icon(
                  [
                    Icons.change_history,
                    Icons.diamond_outlined,
                    Icons.square,
                    Icons.circle,
                  ][widget.index],
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.text,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              if (locked && widget.correct)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle,
                    semanticLabel: 'Alternativa correta',
                  ),
                ),
              if (locked && widget.selected && !widget.correct)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.cancel,
                    semanticLabel: 'Sua resposta não está correta',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
