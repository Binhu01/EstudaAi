import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_entry.dart';
import 'error_review_screen.dart';
import 'study_history_models.dart';
import 'study_history_widgets.dart';

class ErrorReviewBatch {
  ErrorReviewBatch({
    required this.userId,
    required this.sessionGeneration,
    required this.area,
    required List<StudyErrorItem> items,
  }) : items = List.unmodifiable(items.take(5));
  final String userId;
  final int sessionGeneration;
  final LearningArea area;
  final List<StudyErrorItem> items;
}

class ErrorReviewBatchScreen extends ConsumerStatefulWidget {
  const ErrorReviewBatchScreen({super.key, this.batch});
  final ErrorReviewBatch? batch;
  @override
  ConsumerState<ErrorReviewBatchScreen> createState() =>
      _ErrorReviewBatchState();
}

class _ErrorReviewBatchState extends ConsumerState<ErrorReviewBatchScreen> {
  int _index = 0, _reviewed = 0, _pending = 0, _skipped = 0;
  void _next(int expected, ConfirmedAnswer? answer) {
    if (expected != _index) return;
    final item = widget.batch!.items[_index];
    if (answer != null &&
        (answer.input.topicId != item.topicId ||
            answer.input.questionId != item.questionId ||
            answer.input.contentVersion != item.contentVersion)) {
      return;
    }
    setState(() {
      if (answer == null) {
        _skipped++;
      } else if (answer.correct) {
        _reviewed++;
      } else {
        _pending++;
      }
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider), batch = widget.batch;
    if (!session.isAuthenticated) {
      return const StudyHistoryPage(
        title: 'Revisão de erros',
        children: [HistoryLoginGate()],
      );
    }
    if (batch == null ||
        batch.items.isEmpty ||
        batch.userId != session.profile!.id ||
        batch.sessionGeneration != session.generation ||
        batch.area != ref.watch(learningProvider).area) {
      return StudyHistoryPage(
        title: 'Revisão de erros',
        children: [
          const Text('Abra uma nova rodada pelo seu caderno de erros.'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.go('/meus-erros'),
            child: const Text('Voltar ao caderno'),
          ),
        ],
      );
    }
    if (_index == batch.items.length) {
      return StudyHistoryPage(
        title: 'Revisão concluída',
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            '$_reviewed ${_reviewed == 1 ? 'questão revisada' : 'questões revisadas'}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            '$_pending ${_pending == 1 ? 'questão continua pendente' : 'questões continuam pendentes'}',
          ),
          if (_skipped > 0) ...[
            const SizedBox(height: 12),
            Text(
              '$_skipped ${_skipped == 1 ? 'questão não revisada nesta rodada' : 'questões não revisadas nesta rodada'}',
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Acertos confirmados atualizam seu caderno. Volte aos exemplos e tente novamente os assuntos que ainda precisam de revisão.',
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => context.go('/meus-erros'),
                child: const Text('Voltar ao caderno'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/meu-estudo'),
                child: const Text('Ver meu progresso'),
              ),
            ],
          ),
        ],
      );
    }
    final item = batch.items[_index], index = _index;
    return ErrorReviewScreen(
      key: ValueKey(item.key),
      topicId: item.topicId,
      contentVersion: item.contentVersion,
      questionId: item.questionId,
      title: 'Revisão de erros',
      roundProgress: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Questão ${index + 1} de ${batch.items.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: index / batch.items.length,
            semanticsLabel: 'Progresso da revisão',
          ),
          const SizedBox(height: 24),
        ],
      ),
      onContinue: (answer) => _next(index, answer),
      nextLabel: index + 1 == batch.items.length
          ? 'Concluir revisão'
          : 'Próxima revisão',
    );
  }
}
