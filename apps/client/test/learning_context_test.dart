import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/learning/study_catalog.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';
import 'package:estuda_ai/features/learning/learning_entry.dart';
import 'package:estuda_ai/features/contests/contest_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('remembers_each_area_and_advances_generation', () async {
    final free = await loadCatalog(rootBundle),
        contests = await loadContestCatalog(rootBundle);
    final c = ProviderContainer(
      overrides: [
        catalogProvider.overrideWith((ref) async => free),
        contestCatalogProvider.overrideWith((ref) async => contests),
      ],
    );
    addTearDown(c.dispose);
    await c.read(catalogProvider.future);
    await c.read(contestCatalogProvider.future);
    final controller = c.read(learningProvider.notifier);
    controller.selectTopic('bb2026-b01');
    expect(c.read(learningProvider).generation, 1);
    controller.selectTopic('bb2026-r02');
    controller.enterArea(LearningArea.freeStudy);
    expect(c.read(learningProvider).topicId, 'porcentagem');
    controller.enterArea(LearningArea.contest);
    expect(c.read(learningProvider).topicId, 'bb2026-r02');
    expect(c.read(learningProvider).freeTopicId, 'porcentagem');
    expect(c.read(learningProvider).contestTopicId, 'bb2026-r02');
    expect(c.read(learningProvider).generation, 4);
    controller.selectTopic('bb2026-r02');
    expect(c.read(learningProvider).generation, 4);
    expect(() => controller.selectTopic('bb2026-unknown'), throwsArgumentError);
    expect(c.read(learningProvider).generation, 4);
  });
  test(
    'topic changes invalidate context while invalid selections preserve it',
    () async {
      final catalog = await loadCatalog(rootBundle);
      final container = ProviderContainer(
        overrides: [catalogProvider.overrideWith((ref) async => catalog)],
      );
      addTearDown(container.dispose);
      await container.read(catalogProvider.future);
      final controller = container.read(learningProvider.notifier);
      expect(container.read(learningProvider).topicId, 'porcentagem');
      controller.selectTopic('ecologia');
      expect(container.read(learningProvider).generation, 1);
      controller.selectTopic('ecologia');
      expect(container.read(learningProvider).generation, 1);
      expect(() => controller.selectTopic('missing'), throwsArgumentError);
      expect(container.read(learningProvider).topicId, 'ecologia');
      controller.selectTopic('porcentagem');
      expect(container.read(learningProvider).generation, 2);
    },
  );
}
