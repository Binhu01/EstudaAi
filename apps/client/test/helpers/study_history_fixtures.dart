import 'dart:convert';
import 'dart:io';

import 'package:estuda_ai/features/learning/learning_entry.dart';
import 'package:estuda_ai/features/learning/study_catalog.dart';

const historyUser = '11111111-1111-4111-8111-111111111111';
const historyGoal = '33333333-3333-4333-8333-333333333333';
const historyBbGoal = '44444444-4444-4444-8444-444444444444';
const historyAnswer = '55555555-5555-4555-8555-555555555555';
LearningCatalog historyCatalog() => LearningCatalog.fromJson(
  jsonDecode(File('assets/study/catalog.json').readAsStringSync())
      as Map<String, dynamic>,
);
LearningEntry? historyEntry(String id) {
  final t = historyCatalog().find(id);
  return t == null ? null : LearningEntry.fromFree(t, 1);
}

Map<String, Object> goalReply([String scope = 'freeStudy']) => {
  'id': scope == 'freeStudy' ? historyGoal : historyBbGoal,
  'scope': scope,
  'timezone': 'America/Sao_Paulo',
  'dailyTarget': 10,
};
Map<String, Object?> dashboardReply() => {
  'goal': goalReply(),
  'today': {
    'date': '2026-10-02',
    'differentQuestions': 2,
    'attempts': 3,
    'correct': 1,
  },
  'pendingErrors': 2,
  'activity': [
    for (final date in [
      '2026-09-26',
      '2026-09-27',
      '2026-09-28',
      '2026-09-29',
      '2026-09-30',
      '2026-10-01',
    ])
      {'date': date, 'differentQuestions': 0, 'attempts': 0, 'correct': 0},
    {
      'date': '2026-10-02',
      'differentQuestions': 2,
      'attempts': 3,
      'correct': 1,
    },
  ],
  'subjects': [
    {'id': 'porcentagem', 'title': 'Porcentagem', 'attempts': 3, 'correct': 1},
  ],
  'resume': {'topicId': 'porcentagem', 'contentVersion': 1},
};
