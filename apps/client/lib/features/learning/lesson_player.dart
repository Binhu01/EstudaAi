import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'study_catalog.dart';
import 'external_links.dart';
import 'lesson_player_native.dart'
    if (dart.library.js_interop) 'lesson_player_web.dart'
    as platform;

class LessonPlayer extends ConsumerWidget {
  const LessonPlayer({super.key, required this.lesson});
  final StudyLesson lesson;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      platform.VideoFrame(key: ValueKey(lesson.videoId), lesson: lesson),
      const SizedBox(height: 12),
      Text('${lesson.title} · ${lesson.channel}'),
      const SizedBox(height: 8),
      Text(
        'Se o vídeo não carregar aqui, use o link abaixo. O player é fornecido pelo YouTube.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: const Text('Abrir no YouTube'),
          onPressed: () async {
            final opened = await ref.read(externalLinkProvider)(
              Uri.parse(lesson.watchUrl),
            );
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Não foi possível abrir o vídeo. Tente novamente.',
                  ),
                ),
              );
            }
          },
        ),
      ),
    ],
  );
}
