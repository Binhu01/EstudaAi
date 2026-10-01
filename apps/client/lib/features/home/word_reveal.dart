import 'package:flutter/material.dart';

class WordReveal extends StatefulWidget {
  const WordReveal(
    this.text, {
    super.key,
    required this.style,
    required this.animate,
    required this.visible,
  });
  final String text;
  final TextStyle style;
  final bool animate, visible;
  @override
  State<WordReveal> createState() => _WordRevealState();
}

class _WordRevealState extends State<WordReveal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _foreground = true;
  void _sync() {
    final enabled =
        widget.animate &&
        widget.visible &&
        _foreground &&
        !MediaQuery.disableAnimationsOf(context);
    if (enabled && _controller.value < 1) {
      _controller.forward();
    } else if (!enabled) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(WordReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.text.split(' ');
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < words.length; i++)
                  TextSpan(
                    text: '${words[i]}${i < words.length - 1 ? ' ' : ''}',
                    style: TextStyle(
                      color:
                          (widget.style.color ??
                                  Theme.of(context).colorScheme.onSurface)
                              .withValues(
                                alpha:
                                    ((_controller.value -
                                                i / words.length * .5) *
                                            2)
                                        .clamp(0, 1),
                              ),
                    ),
                  ),
              ],
            ),
            style: widget.style,
          ),
        ),
      ),
    );
  }
}
