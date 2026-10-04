import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../settings/settings_controller.dart';
import '../learning/learning_controller.dart';
import '../../design_system/tokens.dart';
import '../../design_system/components/page_heading.dart';
import 'education_hero.dart';
import 'topic_picker.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final _hero = GlobalKey(), _topics = GlobalKey();
  final _gradient = GlobalKey();
  bool _visible = true;
  bool _shaderVisible = true;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    final box = _hero.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !mounted) return;
    final y = box.localToGlobal(Offset.zero).dy;
    final visible =
        y + box.size.height > 0 && y < MediaQuery.sizeOf(context).height;
    final shaderBox = _gradient.currentContext?.findRenderObject();
    var shaderVisible = visible;
    if (shaderBox is RenderBox && shaderBox.hasSize) {
      final shaderY = shaderBox.localToGlobal(Offset.zero).dy;
      shaderVisible =
          shaderY + shaderBox.size.height > 0 &&
          shaderY < MediaQuery.sizeOf(context).height;
    }
    if (visible != _visible || shaderVisible != _shaderVisible) {
      setState(() {
        _visible = visible;
        _shaderVisible = shaderVisible;
      });
    }
  }

  void _choose() {
    final target = _topics.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 400),
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: _scroll,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EducationHero(
          key: _hero,
          gradientKey: _gradient,
          shaderVisible: _shaderVisible,
          animate: ref.watch(settingsProvider).animate,
          visible: _visible,
          onChooseTopic: _choose,
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 20 : 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/meu-estudo'),
                      icon: const Icon(Icons.today_outlined),
                      label: const Text('Meu estudo'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    key: _topics,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageHeading(
                        eyebrow: 'Seu próximo assunto',
                        title: 'Estudo livre',
                        description: 'Escolha uma curiosidade para transformar em conhecimento.',
                      ),
                      const SizedBox(height: 24),
                      ref
                          .watch(catalogProvider)
                          .when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stack) => Column(
                              children: [
                                const Text(
                                  'Não foi possível carregar os assuntos.',
                                ),
                                TextButton(
                                  onPressed: () =>
                                      ref.invalidate(catalogProvider),
                                  child: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                            data: (catalog) => TopicPicker(
                              topics: catalog.topics,
                              selectedId: ref.watch(learningProvider).topicId,
                              onSelected: ref
                                  .read(learningProvider.notifier)
                                  .selectTopic,
                            ),
                          ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => context.go(
                          '/aprender/${ref.read(learningProvider).topicId}',
                        ),
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Aprender com videoaulas'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.go(
                          '/desafios/${ref.read(learningProvider).topicId}',
                        ),
                        icon: const Icon(Icons.quiz_outlined),
                        label: const Text('Jogar um desafio'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.go(
                          '/steve/${ref.read(learningProvider).topicId}',
                        ),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Conversar com o Steve'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.section),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
