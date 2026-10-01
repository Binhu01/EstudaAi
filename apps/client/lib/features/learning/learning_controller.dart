import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'study_catalog.dart';

final catalogProvider = FutureProvider<LearningCatalog>(
  (ref) => loadCatalog(rootBundle),
);

class LearningState {
  const LearningState({this.topicId = 'porcentagem', this.generation = 0});
  final String topicId;
  final int generation;
}

final learningProvider = NotifierProvider<LearningController, LearningState>(
  LearningController.new,
);

class LearningController extends Notifier<LearningState> {
  @override
  LearningState build() => const LearningState();
  void selectTopic(String id) {
    final catalog = ref.read(catalogProvider).asData?.value;
    if (catalog == null || catalog.find(id) == null)
      throw ArgumentError.value(id, 'topicId');
    if (state.topicId != id)
      state = LearningState(topicId: id, generation: state.generation + 1);
  }
}
