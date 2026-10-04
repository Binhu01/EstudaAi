import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_failure.dart';
import '../../design_system/components/page_heading.dart';
import '../../design_system/components/study_card.dart';
import '../../design_system/tokens.dart';
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
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 20 : 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeading(
                eyebrow: title == 'Seu estudo de hoje'
                    ? 'MEU ESTUDO'
                    : 'APRENDER COM CADA TENTATIVA',
                title: title,
                description: title == 'Seu estudo de hoje'
                    ? 'Um passo de cada vez. Veja seu progresso e escolha o próximo.'
                    : null,
              ),
              const SizedBox(height: 28),
              ...children,
              const SizedBox(height: 24),
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
          avatar: const Icon(Icons.menu_book_outlined, size: 18),
          label: const Text('Estudo livre'),
          selected: area == LearningArea.freeStudy,
          onSelected: free.hasValue
              ? (_) => ref
                    .read(learningProvider.notifier)
                    .enterArea(LearningArea.freeStudy)
              : null,
        ),
        ChoiceChip(
          avatar: const Icon(Icons.account_balance_outlined, size: 18),
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
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return StudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              color: colors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Seu estudo acompanha você',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Entre na sua conta para guardar suas respostas, acompanhar o dia e revisar os erros.',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.muted),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/conta'),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Entrar para salvar meu estudo'),
          ),
        ],
      ),
    );
  }
}

class HistoryFailure extends StatelessWidget {
  const HistoryFailure({super.key, required this.error, required this.onRetry});
  final ApiFailure error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.errorSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.errorInk),
            const SizedBox(height: 8),
            Text(
              safeFailureMessage(error.code),
              style: TextStyle(color: colors.errorInk),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.description,
  });
  final String title;
  final String? description;
  final IconData? icon;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return StudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(icon, color: colors.primary, size: 24),
            ),
            const SizedBox(height: 16),
          ],
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(description!, style: TextStyle(color: colors.muted)),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
