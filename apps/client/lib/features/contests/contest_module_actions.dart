import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../learning/learning_entry.dart';
import '../learning/study_routes.dart';

class ContestModuleActions extends StatelessWidget {
  const ContestModuleActions({
    super.key,
    required this.entry,
    required this.selected,
  });
  final LearningEntry entry;
  final StudyAction selected;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final action in StudyAction.values)
        OutlinedButton.icon(
          onPressed: () => context.go(StudyRoutes.path(entry, action)),
          style: action == selected
              ? OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer,
                )
              : null,
          icon: Icon(switch (action) {
            StudyAction.material => Icons.menu_book_outlined,
            StudyAction.lessons => Icons.play_circle_outline,
            StudyAction.quiz => Icons.sports_esports_outlined,
            StudyAction.steve => Icons.chat_bubble_outline,
          }),
          label: Text(switch (action) {
            StudyAction.material => 'Material',
            StudyAction.lessons => 'Aulas de apoio',
            StudyAction.quiz => 'Desafio 8 bits',
            StudyAction.steve => 'Steve',
          }),
        ),
    ],
  );
}
