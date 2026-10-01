import 'package:flutter/material.dart';

import 'components/buttons.dart';
import 'components/feedback.dart';
import 'components/states.dart';
import 'components/study_card.dart';
import 'tokens.dart';

class ComponentGallery extends StatelessWidget {
  const ComponentGallery({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xxl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Galeria de desenvolvimento',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            PrimaryButton(
              label: 'Ação principal',
              onPressed: () =>
                  AppSnackbar.show(context, 'Feedback de demonstração'),
            ),
            SecondaryButton(
              label: 'Abrir modal',
              onPressed: () => AppModal.show(
                context,
                title: 'Exemplo de modal',
                content: const Text('Componente de desenvolvimento.'),
              ),
            ),
            AccentButton(
              label: 'Desafio',
              onPressed: () => AppBottomSheet.show(
                context,
                const Text('Exemplo de bottom sheet.'),
              ),
            ),
            const PrimaryButton(label: 'Indisponível', onPressed: null),
            const AppChip(label: 'Revisão', icon: AppIcons.review),
            const AppBadge(label: 'Exemplo'),
          ],
        ),
        const SizedBox(height: 24),
        const StudyCard(
          child: ProgressBar(value: 0.6, label: 'Exemplo de progresso'),
        ),
        const SizedBox(height: 24),
        const StudyCard(
          child: EmptyState(
            title: 'Estado vazio',
            message: 'Exemplo isolado do fluxo real.',
          ),
        ),
        const SizedBox(height: 24),
        const Skeleton(width: 200),
        const SizedBox(height: 24),
        const LoadingState(),
      ],
    ),
  );
}
