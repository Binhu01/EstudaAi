import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/learning/learning_entry.dart';
import 'package:estuda_ai/features/learning/learning_catalog_providers.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';
import 'package:estuda_ai/features/learning/study_catalog.dart';
import 'package:estuda_ai/features/contests/contest_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('isolates_free_and_contest_catalogs', () async {
    final free = await loadCatalog(rootBundle);
    final contests = await loadContestCatalog(rootBundle);
    expect(free.topics.length, 3);
    final entries = [
      for (final t in free.topics)
        LearningEntry.fromFree(t, free.catalogVersion),
      for (final d in contests.disciplines)
        for (final m in d.modules)
          LearningEntry.fromContest(contests, contests.find(m.id)!),
    ];
    expect(entries.length, 129);
    expect(entries.map((e) => e.topic.id).toSet().length, 129);
    expect(entries.map((e) => e.contentVersion).toSet(), {1});
    final b = entries.firstWhere((e) => e.topic.id == 'bb2026-b01');
    expect(b.area, LearningArea.contest);
    expect(b.topic.questions.length, 6);
    expect(b.topic.lessons.first, b.contestLocation!.discipline.lessons.first);
    expect(b.topic.notes, b.contestLocation!.module.notes);
    expect(b.suggestions.length, 3);
    expect(contests.find('bb2026-missing'), isNull);
  });
  test('contest_error_keeps_free_entry', () async {
    final free = await loadCatalog(rootBundle);
    final container = ProviderContainer(
      overrides: [
        catalogProvider.overrideWith((ref) async => free),
        contestCatalogProvider.overrideWith(
          (ref) async => throw const FormatException('bad contest'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(catalogProvider.future);
    await expectLater(
      container.read(contestCatalogProvider.future),
      throwsFormatException,
    );
    expect(
      container.read(learningEntryProvider('porcentagem')).requireValue!.area,
      LearningArea.freeStudy,
    );
    expect(
      container.read(learningEntryProvider('bb2026-b01')).hasError,
      isTrue,
    );
    expect(
      container.read(learningEntryProvider('missing')).requireValue,
      isNull,
    );
  });
}
