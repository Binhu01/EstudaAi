import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/study_card.dart';
import '../../design_system/tokens.dart';
import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_entry.dart';
import '../learning/learning_entry_view.dart';
import '../learning/study_catalog.dart';
import '../learning/study_routes.dart';
import '../quiz/answer_tile.dart';
import 'answer_submission.dart';
import 'study_context_controller.dart';
import 'study_history_api.dart';
import 'study_history_models.dart';
import 'study_history_widgets.dart';

class ErrorReviewScreen extends StatelessWidget {
  const ErrorReviewScreen({
    super.key,
    required this.topicId,
    required this.contentVersion,
    required this.questionId,
    this.title = 'Revisar uma questão',
    this.roundProgress,
    this.onContinue,
    this.nextLabel = 'Próxima revisão',
  });
  final String topicId, questionId;
  final int? contentVersion;
  final String title, nextLabel;
  final Widget? roundProgress;
  final void Function(ConfirmedAnswer?)? onContinue;
  @override
  Widget build(BuildContext context) => LearningEntryView(
    topicId: topicId,
    area: topicId.startsWith('bb2026-')
        ? LearningArea.contest
        : LearningArea.freeStudy,
    builder: (entry) {
      final q = entry.contentVersion == contentVersion
          ? entry.topic.questions.where((q) => q.id == questionId).firstOrNull
          : null;
      return StudyHistoryPage(
        title: title,
        children: [
          ?roundProgress,
          Text(
            entry.topic.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          if (q == null) ...[
            const Text(
              'Esta questão pertence a uma versão anterior ou não está mais disponível. Seu registro continua no histórico.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  context.go(StudyRoutes.path(entry, StudyAction.lessons)),
              child: const Text('Estudar conteúdo atual'),
            ),
            if (onContinue != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => onContinue!(null),
                child: const Text('Pular questão indisponível'),
              ),
            ],
          ] else
            _Review(
              key: ValueKey('$topicId:$contentVersion:$questionId'),
              entry: entry,
              question: q,
              onContinue: onContinue,
              nextLabel: nextLabel,
            ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (entry.contestLocation != null)
                OutlinedButton(
                  onPressed: () =>
                      context.go(StudyRoutes.path(entry, StudyAction.material)),
                  child: const Text('Ver material'),
                ),
              OutlinedButton(
                onPressed: () =>
                    context.go(StudyRoutes.path(entry, StudyAction.lessons)),
                child: const Text('Ver videoaulas'),
              ),
              OutlinedButton(
                onPressed: () =>
                    context.go(StudyRoutes.path(entry, StudyAction.steve)),
                child: const Text('Perguntar ao Steve'),
              ),
              TextButton(
                onPressed: () => context.go('/meus-erros'),
                child: const Text('Voltar ao caderno'),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _Review extends ConsumerStatefulWidget {
  const _Review({
    super.key,
    required this.entry,
    required this.question,
    this.onContinue,
    this.nextLabel = 'Próxima revisão',
  });
  final LearningEntry entry;
  final StudyQuestion question;
  final void Function(ConfirmedAnswer?)? onContinue;
  final String nextLabel;
  @override
  ConsumerState<_Review> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<_Review> {
  late final AnswerSubmissionController _submission;
  int? _selected;
  bool _disposing = false;
  @override
  void initState() {
    super.initState();
    _submission = AnswerSubmissionController(
      api: () => ref.read(studyHistoryApiProvider),
      capture: () {
        if (ref.read(learningProvider).topicId != widget.entry.topic.id) {
          return Future.value(null);
        }
        return ref.read(studyContextProvider.notifier).capture();
      },
      stillCurrent: (snapshot) =>
          mounted &&
          !_disposing &&
          ref.read(studyContextProvider.notifier).isCurrent(snapshot),
      onChanged: (_) {
        if (mounted && !_disposing) setState(() {});
      },
      onConfirmed: (snapshot) =>
          ref.read(studyContextProvider.notifier).noteConfirmed(snapshot),
    );
  }

  @override
  void dispose() {
    _disposing = true;
    _submission.cancel();
    super.dispose();
  }

  void _reset() {
    _submission.cancel();
    if (mounted) setState(() => _selected = null);
  }

  void _answer(int index) {
    if (_selected != null) return;
    setState(() => _selected = index);
    unawaited(
      _submission.submit(
        StudyAnswerInput(
          topicId: widget.entry.topic.id,
          contentVersion: widget.entry.contentVersion,
          questionId: widget.question.id,
          optionIndex: index,
          source: AnswerSource.review,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (a, b) {
      if (a?.generation != b.generation || a?.profile?.id != b.profile?.id) {
        _reset();
      }
    });
    ref.listen(learningProvider, (a, b) {
      if (a?.generation != b.generation) _reset();
    });
    if (!ref.watch(sessionProvider).isAuthenticated) {
      return const HistoryLoginGate();
    }
    final q = widget.question,
        locked = _selected != null,
        state = _submission.state;
    final colors = AppColors.of(context);
    return StudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'UMA NOVA TENTATIVA',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 12),
          Text(q.prompt, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnswerTile(
                index: i,
                text: q.options[i],
                selected: _selected == i,
                correct: locked && q.correctIndex == i,
                onPressed: locked ? null : () => _answer(i),
              ),
            ),
          if (locked) ...[
            const SizedBox(height: 12),
            Text(
              _selected == q.correctIndex
                  ? 'Resposta correta!'
                  : 'Vamos aprender com essa resposta',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _selected == q.correctIndex
                    ? colors.successSoft
                    : colors.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                q.explanation,
                style: TextStyle(
                  color: _selected == q.correctIndex
                      ? colors.successInk
                      : colors.accentInk,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (state.status == SubmissionStatus.sending)
              Semantics(
                liveRegion: true,
                child: const Text('Confirmando sua resposta…'),
              ),
            if (state.status == SubmissionStatus.confirmed)
              Semantics(
                liveRegion: true,
                child: Text(
                  state.answer!.correct
                      ? 'Revisado'
                      : 'Ainda pendente de revisão',
                ),
              ),
            if (state.status == SubmissionStatus.unconfirmed) ...[
              Semantics(
                liveRegion: true,
                child: const Text(
                  'Não foi possível confirmar o registro desta resposta. Tente novamente ou continue estudando.',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: _submission.retry,
                    child: const Text('Tentar novamente'),
                  ),
                  TextButton(
                    onPressed: () {
                      _submission.continueStudy();
                      if (widget.onContinue != null) {
                        widget.onContinue!(null);
                      } else {
                        context.go('/meus-erros');
                      }
                    },
                    child: Text(
                      widget.onContinue == null
                          ? 'Continuar estudo'
                          : 'Pular sem salvar',
                    ),
                  ),
                ],
              ),
            ],
            if (widget.onContinue != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: state.status == SubmissionStatus.confirmed
                    ? () => widget.onContinue!(state.answer)
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(widget.nextLabel),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
