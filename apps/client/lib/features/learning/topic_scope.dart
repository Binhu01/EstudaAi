import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'learning_controller.dart';

class TopicScope extends ConsumerStatefulWidget {
  const TopicScope({super.key, required this.topicId, required this.child});
  final String topicId;
  final Widget child;
  @override
  ConsumerState<TopicScope> createState() => _TopicScopeState();
}

class _TopicScopeState extends ConsumerState<TopicScope> {
  void _sync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(learningProvider.notifier).selectTopic(widget.topicId);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(TopicScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topicId != widget.topicId) _sync();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
