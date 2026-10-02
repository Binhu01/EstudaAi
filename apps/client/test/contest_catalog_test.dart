import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/contests/contest_catalog.dart';
import 'package:estuda_ai/features/learning/study_catalog.dart';

Map<String, dynamic> fixture() => jsonDecode(
  File('../../tools/test/fixtures/contest-catalog.json').readAsStringSync(),
) as Map<String, dynamic>;
void main() {
  test('accepts_valid_contest_and_rejects_mutations', () {
    final c = ContestCatalog.fromJson(fixture());
    expect(c.disciplines.expand((d) => d.modules).length, 126);
    expect(
      c.disciplines.expand((d) => d.modules).expand((m) => m.questions).length,
      756,
    );
    expect(c.find('bb2026-f07')?.discipline.id, 'financeira');
    expect(c.find('missing'), isNull);
    final mutations = <void Function(dynamic, dynamic)>[
      (r, m) => r['schemaVersion'] = 2,
      (r, m) => r['course']['referenceDate'] = '2026-02-30',
      (r, m) => r['course']['id'] = 'other',
      (r, m) => m['id'] = 'bb2026-f01',
      (r, m) => r['disciplines'][0]['modules'].removeLast(),
      (r, m) => m['questions'].removeLast(),
      (r, m) => m['questions'][0]['options'] = ['A', ' a ', 'C', 'D'],
      (r, m) => m['questions'][0]['correctIndex'] = 4,
      (r, m) => m['blocks'][0]['type'] = 'html',
      (r, m) => m['blocks'][4]['rows'] = [
        ['one'],
      ],
      (r, m) => m['lessonIds'] = ['bb2026-financeira-video-1'],
      (r, m) =>
          m['sources'][0]['url'] = 'https://user:password@example.org/ref',
      (r, m) => m['coverage'][0]['questionIds'] = ['bb2026-f01-q01'],
      (r, m) => m['writingTasks'] = [
        r['disciplines'][8]['modules'][0]['writingTasks'][0],
      ],
    ];
    for (var i = 0; i < mutations.length; i++) {
      final r = fixture();
      mutations[i](r, r['disciplines'][0]['modules'][0]);
      expect(
        () => ContestCatalog.fromJson(r),
        throwsFormatException,
        reason: 'mutation $i',
      );
    }
  });
  test('free_parser_remains_strict', () {
    final r = fixture();
    final m = Map<String, dynamic>.from(r['disciplines'][0]['modules'][0]);
    m['subject'] = 'Teste';
    m['lessons'] = r['disciplines'][0]['lessons'];
    expect(() => StudyTopic.parse(m), throwsFormatException);
  });
}
