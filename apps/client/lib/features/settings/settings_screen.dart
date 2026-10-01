import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens.dart';
import '../../design_system/components/study_card.dart';
import '../../design_system/components/feedback.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colors = AppColors.of(context);
    Future<void> update({ThemeMode? theme, bool? animate}) async {
      try {
        await ref
            .read(settingsProvider.notifier)
            .update(theme: theme, animate: animate);
      } catch (_) {
        if (context.mounted) {
          AppSnackbar.show(
            context,
            'Não foi possível salvar a preferência. Tente novamente.',
          );
        }
      }
    }

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600
                  ? AppSpacing.lg
                  : AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferências',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Um ambiente confortável para você se concentrar.',
                  style: TextStyle(color: colors.muted),
                ),
                const SizedBox(height: AppSpacing.xxl),
                StudyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aparência',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Escolha um tema ou acompanhe a configuração do seu dispositivo.',
                        style: TextStyle(color: colors.muted),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final option in const [
                            (
                              ThemeMode.system,
                              'Sistema',
                              Icons.brightness_auto_outlined,
                            ),
                            (
                              ThemeMode.light,
                              'Claro',
                              Icons.light_mode_outlined,
                            ),
                            (
                              ThemeMode.dark,
                              'Escuro',
                              Icons.dark_mode_outlined,
                            ),
                          ])
                            ChoiceChip(
                              label: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                child: Text(option.$2),
                              ),
                              avatar: Icon(option.$3, size: 20),
                              selected: settings.theme == option.$1,
                              onSelected: (_) => update(theme: option.$1),
                              showCheckmark: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                StudyCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.all(AppSpacing.xl),
                    title: const Text('Animação de fundo'),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Movimento suave na tela inicial. A preferência de movimento reduzido do dispositivo é respeitada.',
                      ),
                    ),
                    value: settings.animate,
                    onChanged: (value) => update(animate: value),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                StudyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Um espaço para cada meta',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Os conteúdos, cronogramas e resultados de cada objetivo ficam no seu próprio contexto de estudo.',
                        style: TextStyle(color: colors.muted, height: 1.6),
                      ),
                    ],
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.xl),
                  TextButton.icon(
                    onPressed: () => context.go('/componentes'),
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Galeria de componentes'),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Estuda Aí · 0.1.0',
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
