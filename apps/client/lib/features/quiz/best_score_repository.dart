import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';

final bestScoreProvider = Provider<BestScoreRepository>(
  (ref) => BestScoreRepository(ref.watch(preferencesProvider)),
);

class BestScoreRepository {
  BestScoreRepository(this.preferences);
  final SharedPreferences preferences;
  Future<void> _pending = Future.value();
  String _key(String topicId, int version) => 'quiz.best.v$version.$topicId';
  int read(String topicId, int catalogVersion) {
    final value = preferences.get(_key(topicId, catalogVersion));
    return value is int && value >= 0 && value <= 700 ? value : 0;
  }

  Future<void> saveIfHigher(String topicId, int catalogVersion, int score) {
    if (score < 0 || score > 700) {
      return Future.error(ArgumentError.value(score));
    }
    final operation = _pending.then((_) async {
      if (score > read(topicId, catalogVersion)) {
        if (!await preferences.setInt(_key(topicId, catalogVersion), score)) {
          throw StateError('Não foi possível salvar o recorde.');
        }
      }
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}
