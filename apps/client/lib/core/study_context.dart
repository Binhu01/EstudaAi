import 'dart:convert';

class StudyContext {
  const StudyContext(this.userId, this.goalId);
  final String userId;
  final String goalId;
  String cacheKey(
    String resource, [
    Map<String, String> parameters = const {},
  ]) {
    final entries = parameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return jsonEncode([
      userId,
      goalId,
      resource,
      entries.map((e) => [e.key, e.value]).toList(),
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is StudyContext && other.userId == userId && other.goalId == goalId;
  @override
  int get hashCode => Object.hash(userId, goalId);
}

class ContextGate {
  StudyContext? _active;
  int _generation = 0;
  final Map<Object, void Function()> _pending = {};
  StudyContext? get active => _active;
  void activate(StudyContext? context) {
    _active = context;
    _generation++;
    final cancellations = _pending.values.toList();
    _pending.clear();
    for (final cancel in cancellations) {
      try {
        cancel();
      } catch (_) {
        /* Stale results are still discarded. */
      }
    }
  }

  Future<T?> run<T>(
    StudyContext context,
    Future<T> Function() load, {
    void Function()? cancel,
  }) async {
    if (_active != context) return null;
    final generation = _generation;
    final request = Object();
    if (cancel != null) _pending[request] = cancel;
    try {
      final result = await load();
      return generation == _generation && _active == context ? result : null;
    } catch (_) {
      if (generation != _generation || _active != context) return null;
      rethrow;
    } finally {
      _pending.remove(request);
    }
  }
}
