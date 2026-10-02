import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'study_catalog.dart';
import 'learning_entry.dart';
import 'learning_catalog_providers.dart';

final catalogProvider = FutureProvider<LearningCatalog>(
  (ref) => loadCatalog(rootBundle),
);

class LearningState {
  const LearningState({
    this.area = LearningArea.freeStudy,
    this.freeTopicId = 'porcentagem',
    this.contestTopicId = 'bb2026-b01',
    this.generation = 0,
  });
  final LearningArea area;
  final String freeTopicId, contestTopicId;
  String get topicId =>
      area == LearningArea.freeStudy ? freeTopicId : contestTopicId;
  final int generation;
}

final learningProvider = NotifierProvider<LearningController, LearningState>(
  LearningController.new,
);

class LearningController extends Notifier<LearningState> {
  @override
  LearningState build() => const LearningState();
  void selectTopic(String id) {
    final entry = ref.read(learningEntryProvider(id)).asData?.value;
    if (entry == null) {
      throw ArgumentError.value(id, 'topicId');
    }
    if (state.topicId != id || state.area != entry.area) {
      state = LearningState(
        area: entry.area,
        freeTopicId: entry.area == LearningArea.freeStudy
            ? id
            : state.freeTopicId,
        contestTopicId: entry.area == LearningArea.contest
            ? id
            : state.contestTopicId,
        generation: state.generation + 1,
      );
    }
  }

  void enterArea(LearningArea area) => selectTopic(
    area == LearningArea.freeStudy ? state.freeTopicId : state.contestTopicId,
  );
}
