import 'package:flutter/material.dart';

import '../../design_system/tokens.dart';
import '../../design_system/shader/study_gradient.dart';
import 'word_reveal.dart';

class EducationHero extends StatelessWidget {
  const EducationHero({
    super.key,
    required this.onChooseTopic,
    required this.animate,
    required this.visible,
    this.imagePath = 'assets/images/study-hero.webp',
    this.gradientKey,
    this.shaderVisible,
  });
  final VoidCallback onChooseTopic;
  final bool animate, visible;
  final String imagePath;
  final Key? gradientKey;
  final bool? shaderVisible;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              alignment: const Alignment(.2, 0),
              excludeFromSemantics: true,
              errorBuilder: (_, error, stack) =>
                  const ColoredBox(color: AppColors.heroFallback),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.heroScrimTop, AppColors.heroScrimBottom],
                ),
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 550),
            padding: EdgeInsets.all(compact ? 24 : 40),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(AppIcons.brand, color: AppColors.white, size: 20),
                    Text(
                      'UM MUNDO PARA DESCOBRIR',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 56),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 590),
                  child: WordReveal(
                    'Seu próximo nível começa com uma descoberta.',
                    animate: animate,
                    visible: visible,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: compact ? 32 : 44,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: const Text(
                    'Escolha um assunto, aprenda com videoaulas, teste seus conhecimentos e conte com o Steve.',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.heroFallback,
                    minimumSize: const Size(48, 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onPressed: onChooseTopic,
                  icon: const Icon(AppIcons.forward),
                  label: const Text('Escolher meu assunto'),
                ),
                const SizedBox(height: 56),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Estuda Aí',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: compact ? 48 : 76,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                      ),
                    ),
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 92,
                        height: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: StudyGradient(
                            key: gradientKey,
                            animate: animate,
                            visible: shaderVisible ?? visible,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Explore os assuntos abaixo ↓',
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
