import 'package:flutter/material.dart';

import '../../design_system/tokens.dart';
import '../../design_system/shader/study_gradient.dart';
import 'hero_particle_orb.dart';
import 'word_reveal.dart';

class EducationHero extends StatelessWidget {
  const EducationHero({
    super.key,
    required this.onChooseTopic,
    required this.animate,
    required this.visible,
    this.gradientKey,
    this.shaderVisible,
  });
  final VoidCallback onChooseTopic;
  final bool animate, visible;
  final Key? gradientKey;
  final bool? shaderVisible;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
      final compact = constraints.maxWidth < 800 || largeText;
      final minHeight = compact
          ? (MediaQuery.sizeOf(context).height - 144).clamp(620.0, 760.0)
          : (MediaQuery.sizeOf(context).height - 64).clamp(720.0, 860.0);
      final orbSize = largeText ? 200.0 : (compact ? 240.0 : 300.0);
      return ColoredBox(
        color: AurosColors.abyss,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AurosColors.abyss, AurosColors.deep],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1440, minHeight: minHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 600 ? 20 : 48,
                  vertical: compact ? 28 : 40,
                ),
                child: DefaultTextStyle.merge(
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: AppTypography.bodyFamily),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            ExcludeSemantics(
                              child: SizedBox(
                                width: 28,
                                height: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: StudyGradient(
                                    key: gradientKey,
                                    animate: animate,
                                    visible: shaderVisible ?? visible,
                                  ),
                                ),
                              ),
                            ),
                            const Text(
                              'CONHECIMENTO ABRE CAMINHOS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AurosColors.mist,
                                fontFamily: AppTypography.bodyFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.1,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        header: true,
                        child: WordReveal(
                          'Estuda Aí',
                          animate: animate,
                          visible: visible,
                          style: TextStyle(
                            fontFamily: AppTypography.headingFamily,
                            color: Colors.white,
                            fontSize: largeText
                                ? 52
                                : (constraints.maxWidth < 600
                                      ? 64
                                      : (compact ? 76 : 112)),
                            fontWeight: FontWeight.w500,
                            height: 1.05,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: WordReveal(
                          'Seu próximo nível começa com uma descoberta.',
                          animate: animate,
                          visible: visible,
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFamily,
                            color: AurosColors.mist,
                            fontSize: compact ? 20 : 24,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: const Text(
                          'Escolha um assunto, aprenda com videoaulas, teste seus conhecimentos e conte com o Steve.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFamily,
                            color: AurosColors.silver,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: [0, .2625, .4757, .8896],
                              colors: [
                                AurosColors.cyan,
                                AurosColors.mist,
                                Color(0xFFFFFDFA),
                                Color(0xFFFAD1FF),
                              ],
                            ),
                          ),
                          child: FilledButton.icon(
                            style:
                                FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: AurosColors.deep,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  minimumSize: const Size(48, 56),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: AppTypography.bodyFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ).copyWith(
                                  side: WidgetStateProperty.resolveWith(
                                    (states) =>
                                        states.contains(WidgetState.focused)
                                        ? const BorderSide(
                                            color: AurosColors.deep,
                                            width: 2,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                            onPressed: onChooseTopic,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: const Text('Escolher meu assunto'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox.square(
                        dimension: orbSize,
                        child: HeroParticleOrb(
                          animate: animate,
                          visible: visible,
                          // The user explicitly requested this hero to loop.
                          respectReducedMotion: false,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Explore os assuntos abaixo',
                            style: TextStyle(
                              color: AurosColors.silver,
                              fontFamily: AppTypography.bodyFamily,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          ExcludeSemantics(
                            child: Icon(
                              Icons.arrow_downward,
                              color: AurosColors.silver,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
