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
    final background = AppColors.quizAnswers[widget.index];
    final ink = widget.index == 2 ? AppColors.pixelInk : AppColors.white;
    return FilledButton(
      key: ValueKey('answer-${widget.index}'),
      focusNode: _focus,
      onPressed: widget.onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: ink,
        disabledBackgroundColor: background,
        disabledForegroundColor: ink,
        minimumSize: const Size(48, 90),
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            color: widget.selected || widget.correct
                ? AppColors.pixelInk
                : background,
            width: 3,
          ),
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
              size: 23,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          if (widget.onPressed == null && widget.correct)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.check_circle,
                semanticLabel: 'Alternativa correta',
              ),
            ),
          if (widget.onPressed == null && widget.selected && !widget.correct)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.cancel,
                semanticLabel: 'Sua resposta não está correta',
              ),
            ),
        ],
      ),
    );
  }
}
