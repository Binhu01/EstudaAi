import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:estuda_ai/features/quiz/best_score_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('free_score_survives_contest_version', () async {
    SharedPreferences.setMockInitialValues({'quiz.best.v1.porcentagem': 500});
    final repository = BestScoreRepository(
      await SharedPreferences.getInstance(),
    );
    await repository.saveIfHigher('bb2026-b01', 1, 700);
    await repository.saveIfHigher('bb2026-b01', 2, 300);
    expect(repository.read('porcentagem', 1), 500);
    expect(repository.read('bb2026-b01', 1), 700);
    expect(repository.read('bb2026-b01', 2), 300);
  });
  test(
    'concurrent writes preserve the maximum and isolate topic/version',
    () async {
      SharedPreferences.setMockInitialValues({
        'quiz.best.v1.ecologia': 'corrupt',
      });
      final repo = BestScoreRepository(await SharedPreferences.getInstance());
      expect(repo.read('ecologia', 1), 0);
      await Future.wait([
        repo.saveIfHigher('porcentagem', 1, 700),
        repo.saveIfHigher('porcentagem', 1, 300),
      ]);
      await repo.saveIfHigher('porcentagem', 1, 100);
      expect(repo.read('porcentagem', 1), 700);
      expect(repo.read('porcentagem', 2), 0);
      expect(repo.read('ecologia', 1), 0);
      await repo.saveIfHigher('ecologia', 1, 300);
      expect(repo.read('ecologia', 1), 300);
    },
  );
}
