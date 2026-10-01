import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/features/learning/study_catalog.dart';
import 'package:estuda_ai/features/learning/learning_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
