import 'package:flutter/material.dart';

import 'study_catalog.dart';

class VideoFrame extends StatelessWidget {
  const VideoFrame({super.key, required this.lesson});
  final StudyLesson lesson;
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Text('Assista à aula no YouTube pelo botão abaixo.'),
  );
}
