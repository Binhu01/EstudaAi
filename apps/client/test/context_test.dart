import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:estuda_ai/core/study_context.dart';

void main() {
  test('a delayed response from another goal is discarded', () async {
    const first = StudyContext('user', 'concurso');
    const second = StudyContext('user', 'faculdade');
    final gate = ContextGate()..activate(first);
    final pending = Completer<String>();
    final request = gate.run(first, () => pending.future);
    gate.activate(second);
    pending.complete('concurso privado');
    expect(await request, isNull);
    expect(await gate.run(second, () async => 'faculdade'), 'faculdade');
  });
  test(
    'logout and switching away then back invalidate old responses',
    () async {
      const first = StudyContext('user', 'goal');
      final gate = ContextGate()..activate(first);
      final pending = Completer<String>();
      final request = gate.run(first, () => pending.future);
      gate.activate(null);
      gate.activate(first);
      pending.complete('old');
      expect(await request, isNull);
    },
  );
  test('cache keys isolate account, goal and literal query parameters', () {
    const first = StudyContext('a/b', 'c');
    const second = StudyContext('a', 'b/c');
    expect(first.cacheKey('questions'), isNot(second.cacheKey('questions')));
    expect(
      first.cacheKey('questions', {'q': '1'}),
      isNot(first.cacheKey('questions', {'q': '2'})),
    );
    expect(
      first.cacheKey('questions', {'b': '2', 'a': '1'}),
      first.cacheKey('questions', {'a': '1', 'b': '2'}),
    );
  });
  test(
    'changing context cancels pending work and drops cancellation errors',
    () async {
      const context = StudyContext('user', 'goal');
      final gate = ContextGate()..activate(context);
      final pending = Completer<String>();
      var cancelled = false;
      final result = gate.run(
        context,
        () => pending.future,
        cancel: () {
          cancelled = true;
          pending.completeError(StateError('Cancelled'));
        },
      );
      gate.activate(null);
      expect(cancelled, true);
      expect(await result, isNull);
      gate.activate(context);
      cancelled = false;
      expect(
        await gate.run(
          context,
          () async => 'completed',
          cancel: () => cancelled = true,
        ),
        'completed',
      );
      gate.activate(null);
      expect(
        cancelled,
        false,
        reason: 'Completed work releases its cancellation callback.',
      );
    },
  );
}
