import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'study_catalog.dart';

class VideoFrame extends StatefulWidget {
  const VideoFrame({super.key, required this.lesson});
  final StudyLesson lesson;
  @override
  State<VideoFrame> createState() => _VideoFrameState();
}

class _VideoFrameState extends State<VideoFrame> {
  web.HTMLIFrameElement? _frame;
  @override
  void dispose() {
    _frame?.remove();
    _frame = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: math.max(200, constraints.maxWidth * 9 / 16),
      width: math.max(200, constraints.maxWidth),
      child: HtmlElementView.fromTagName(
        tagName: 'iframe',
        onElementCreated: (element) {
          final frame = element as web.HTMLIFrameElement;
          _frame = frame;
          frame.src =
              'https://www.youtube.com/embed/${widget.lesson.videoId}?autoplay=0&rel=0';
          frame.title =
              'Videoaula: ${widget.lesson.title} — ${widget.lesson.channel}';
          frame.allow = 'accelerometer; encrypted-media; gyroscope; picture-in-picture; fullscreen';
          frame.allowFullscreen = true;
          frame.referrerPolicy = 'strict-origin-when-cross-origin';
          frame.style
            ..width = '100%'
            ..height = '100%'
            ..border = '0';
        },
      ),
    ),
  );
}
