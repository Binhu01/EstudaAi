import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/contests/contest_catalog.dart';
import 'package:estuda_ai/features/learning/learning_entry.dart';
import 'package:estuda_ai/features/learning/study_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all_actions_use_contest_prefix', () async {
    final c = await loadContestCatalog(rootBundle);
    final b = LearningEntry.fromContest(c, c.find('bb2026-b01')!);
    final expected = ['material', 'aulas', 'desafio', 'steve'];
    for (var i = 0; i < StudyAction.values.length; i++) {
      expect(
        StudyRoutes.path(b, StudyAction.values[i]),
        '/concursos/bb2026/bancarios/bb2026-b01/${expected[i]}',
      );
    }
  });
}
