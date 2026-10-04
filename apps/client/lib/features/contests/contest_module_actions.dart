import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens.dart';
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
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: [
        for (final action in StudyAction.values)
          Semantics(
            selected: action == selected,
            child: OutlinedButton.icon(
              onPressed: () => context.go(StudyRoutes.path(entry, action)),
              style: OutlinedButton.styleFrom(
                foregroundColor: action == selected
                    ? colors.linkInk
                    : colors.muted,
                backgroundColor: action == selected
                    ? colors.primarySoft
                    : Colors.transparent,
                side: BorderSide(
                  color: action == selected ? colors.primary : colors.border,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              icon: Icon(switch (action) {
                StudyAction.material => Icons.menu_book_outlined,
                StudyAction.lessons => Icons.play_circle_outline,
                StudyAction.quiz => Icons.sports_esports_outlined,
                StudyAction.steve => Icons.chat_bubble_outline,
              }, size: 20),
              label: Text(switch (action) {
                StudyAction.material => 'Material',
                StudyAction.lessons => 'Aulas de apoio',
                StudyAction.quiz => 'Desafio 8 bits',
                StudyAction.steve => 'Steve',
              }),
            ),
          ),
      ],
    );
  }
}
