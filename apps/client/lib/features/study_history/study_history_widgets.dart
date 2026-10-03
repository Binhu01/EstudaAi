import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_failure.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_catalog_providers.dart';
import '../learning/learning_entry.dart';

class StudyHistoryPage extends StatelessWidget {
  const StudyHistoryPage({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

class HistoryAreaPicker extends ConsumerWidget {
  const HistoryAreaPicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(learningProvider).area,
        free = ref.watch(catalogProvider),
        contests = ref.watch(contestCatalogProvider);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ChoiceChip(
          avatar: const Icon(Icons.menu_book_outlined),
          label: const Text('Estudo livre'),
          selected: area == LearningArea.freeStudy,
          onSelected: free.hasValue
              ? (_) => ref
                    .read(learningProvider.notifier)
                    .enterArea(LearningArea.freeStudy)
              : null,
        ),
        ChoiceChip(
          avatar: const Icon(Icons.account_balance_outlined),
          label: const Text('Banco do Brasil'),
          selected: area == LearningArea.contest,
          onSelected: contests.hasValue
              ? (_) => ref
                    .read(learningProvider.notifier)
                    .enterArea(LearningArea.contest)
              : null,
        ),
      ],
    );
  }
}

class HistoryLoginGate extends StatelessWidget {
  const HistoryLoginGate({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_circle_outlined, size: 36),
          const SizedBox(height: 16),
          Text(
            'Seu estudo acompanha você',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Entre na sua conta para guardar suas respostas, acompanhar o dia e revisar os erros.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/conta'),
            child: const Text('Entrar para salvar meu estudo'),
          ),
        ],
      ),
    ),
  );
}

class HistoryFailure extends StatelessWidget {
  const HistoryFailure({super.key, required this.error, required this.onRetry});
  final ApiFailure error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(safeFailureMessage(error.code)),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onRetry,
          child: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}
