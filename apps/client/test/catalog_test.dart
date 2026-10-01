import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/learning/study_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<Map<String, dynamic>> raw() async =>
      jsonDecode(await rootBundle.loadString('assets/study/catalog.json'))
          as Map<String, dynamic>;
  test(
    'catalog connects each topic to playable lessons and a full question pool',
    () async {
      final catalog = await loadCatalog(rootBundle);
      expect(catalog.topics.map((t) => t.id), [
        'porcentagem',
        'interpretacao-texto',
        'ecologia',
      ]);
      expect(catalog.find('missing'), isNull);
      expect(catalog.find('porcentagem')!.lessons.first.videoId, 'TEhv11SkDUs');
      expect(catalog.find('ecologia')!.lessons.last.videoId, 'qj6RWzK7cYI');
      for (final topic in catalog.topics) {
        expect(topic.questions.length, 10);
        expect(topic.lessons.length, 2);
        for (final question in topic.questions) {
          expect(question.options.length, 4);
          expect(question.correctIndex, inInclusiveRange(0, 3));
          expect(question.explanation, isNotEmpty);
        }
      }
    },
  );
  test('malformed choices, duplicate ids and unsafe sources never become study content', () async {
    for (final mutation in <void Function(Map<String, dynamic>)>[
      (d) => (d['topics'] as List)[0]['questions'][0]['correctIndex'] = 4,
      (d) => (d['topics'] as List)[0]['questions'][0]['options'] = [
        'a',
        'a',
        'c',
        'd',
      ],
      (d) => (d['topics'] as List)[1]['id'] = 'porcentagem',
      (d) =>
          (d['topics'] as List)[0]['sources'][0]['url'] = 'javascript:alert(1)',
      (d) => d.remove('schemaVersion'),
    ]) {
      final data = await raw();
      mutation(data);
      expect(() => LearningCatalog.fromJson(data), throwsFormatException);
    }
  });
}
