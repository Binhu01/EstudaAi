import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens.dart';
import '../../design_system/components/study_card.dart';
import '../../design_system/components/states.dart';
import '../../design_system/shader/study_gradient.dart';
import '../settings/settings_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final _hero = GlobalKey();
  bool _visible = true;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkVisibility);
  }

  void _checkVisibility() {
    final box = _hero.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !mounted) return;
    final y = box.localToGlobal(Offset.zero).dy;
    final visible =
        y + box.size.height > 0 && y < MediaQuery.sizeOf(context).height;
    if (visible != _visible) setState(() => _visible = visible);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final animate = ref.watch(settingsProvider).animate;
    return SingleChildScrollView(
      controller: _scroll,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600
                  ? AppSpacing.lg
                  : AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Minha jornada',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Um espaço para cada objetivo. Um próximo passo de cada vez.',
                  style: TextStyle(color: colors.muted, height: 1.5),
                ),
                const SizedBox(height: AppSpacing.xxl),
                ClipRRect(
                  key: _hero,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      Positioned.fill(
                        child: StudyGradient(
                          animate: animate,
                          visible: _visible,
                        ),
                      ),
                      Positioned.fill(
                        child: ColoredBox(
                          color: AppColors.scrim.withValues(alpha: 0.56),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 590),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    AppIcons.brand,
                                    color: AppColors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'APRENDER É CONQUISTAR',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                'O que vamos\nconquistar hoje?',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(color: AppColors.white),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const Text(
                                'Seu objetivo dá a direção.\nSeu desempenho ajuda a escolher o caminho.',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.white,
                                  side: const BorderSide(
                                    color: AppColors.white,
                                  ),
                                ),
                                onPressed: () => context.go('/preferencias'),
                                child: const Text('Personalizar meu espaço'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Suas metas de estudo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                const StudyCard(
                  child: EmptyState(
                    title: 'Nenhuma meta por aqui, ainda',
                    message: 'Cada objetivo terá suas matérias, questões, revisões e progresso. O acesso à conta e a criação de metas chegam na próxima etapa.',
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Diferentes jeitos de aprender',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'A experiência de estudo será construída ao redor de cada assunto.',
                  style: TextStyle(color: colors.muted),
                ),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 760
                        ? (constraints.maxWidth - 48) / 4
                        : constraints.maxWidth >= 440
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final item in const [
                          (
                            AppIcons.video,
                            'Aprender',
                            'Videoaulas e materiais',
                          ),
                          (AppIcons.mindMap, 'Visualizar', 'Mapas mentais'),
                          (
                            AppIcons.questions,
                            'Praticar',
                            'Questões e simulados',
                          ),
                          (
                            AppIcons.flashcards,
                            'Memorizar',
                            'Flashcards e revisões',
                          ),
                        ])
                          SizedBox(
                            width: width,
                            child: StudyCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    item.$1,
                                    color: colors.primary,
                                    size: 25,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  Text(
                                    item.$2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    item.$3,
                                    style: TextStyle(
                                      color: colors.muted,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Feito para o seu ritmo, sem misturar seus objetivos.',
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
