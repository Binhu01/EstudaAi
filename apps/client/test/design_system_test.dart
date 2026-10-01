import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/design_system/tokens.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return ((first > second ? first : second) + 0.05) /
      ((first < second ? first : second) + 0.05);
}

void main() {
  test(
    'quiz alternatives preserve contrast without relying on color alone',
    () {
      for (var i = 0; i < 4; i++) {
        expect(
          contrast(
            i == 2 ? AppColors.pixelInk : AppColors.white,
            AppColors.quizAnswers[i],
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );
  test(
    'text and semantic states preserve at least 4.5 contrast in both themes',
    () {
      for (final colors in [AppColors.light, AppColors.dark]) {
        expect(
          contrast(AppColors.onAccent, colors.accent),
          greaterThanOrEqualTo(4.5),
        );
        for (final pair in [
          (colors.text, colors.surface),
          (colors.muted, colors.background),
          (colors.onPrimary, colors.primary),
          (colors.successInk, colors.successSoft),
          (colors.warningInk, colors.warningSoft),
          (colors.errorInk, colors.errorSoft),
          (colors.accentInk, colors.accentSoft),
        ]) {
          expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        }
      }
    },
  );
}
