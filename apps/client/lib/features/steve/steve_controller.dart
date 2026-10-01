import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_failure.dart';
import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import 'steve_api.dart';
import 'steve_models.dart';

typedef SteveContext = ({
  String topicId,
  String userId,
  int sessionGeneration,
  int topicGeneration,
});
final steveProvider = NotifierProvider.autoDispose
    .family<SteveController, SteveChatState, SteveContext>(SteveController.new);
final steveClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

class SteveController extends Notifier<SteveChatState> {
  SteveController(this.context);
  final SteveContext context;
  int _generation = 0;
  CancelToken? _cancel;
  Timer? _quotaTimer;
  @override
  SteveChatState build() {
    ref.listen(sessionProvider, (_, next) {
      if (!_isCurrent()) newConversation();
    });
    ref.listen(learningProvider, (_, next) {
      if (!_isCurrent()) newConversation();
    });
    ref.onDispose(() {
      _generation++;
      _cancel?.cancel();
      _quotaTimer?.cancel();
    });
    return const SteveChatState();
  }

  bool _isCurrent() {
    if (!ref.mounted) return false;
    final session = ref.read(sessionProvider),
        topic = ref.read(learningProvider);
    return session.isAuthenticated &&
        session.profile?.id == context.userId &&
        session.generation == context.sessionGeneration &&
        topic.topicId == context.topicId &&
        topic.generation == context.topicGeneration;
  }

  void newConversation() {
    _generation++;
    _cancel?.cancel();
    _cancel = null;
    _quotaTimer?.cancel();
    state = const SteveChatState();
  }

  Future<void> send(String text) async {
    if (!_isCurrent() || state.pending) return;
    final message = text.trim();
    if (message.isEmpty || message.length > 2000) {
      state = SteveChatState(
        turns: state.turns,
        quota: state.quota,
        error: const ApiFailure('INVALID_INPUT'),
      );
      return;
    }
    final generation = _generation, cancel = CancelToken();
    final previous = state;
    _cancel = cancel;
    _quotaTimer?.cancel();
    state = SteveChatState(
      turns: previous.turns,
      pending: true,
      pendingQuestion: message,
    );
    try {
      final reply = await ref
          .read(steveApiProvider)
          .send(
            topicId: context.topicId,
            message: message,
            history: previous.history,
            cancelToken: cancel,
          );
      if (!_isCurrent() || generation != _generation) return;
      state = SteveChatState(
        turns: List.unmodifiable([...previous.turns, ChatTurn(message, reply)]),
        quota:
            reply.quota.resetAt.isAfter(ref.read(steveClockProvider)().toUtc())
            ? reply.quota
            : null,
      );
      _scheduleQuotaExpiry(generation);
    } catch (error) {
      if (!_isCurrent() || generation != _generation) return;
      final failure = error is ApiFailure
          ? error
          : const ApiFailure('UNAVAILABLE');
      if (failure.code == 'UNAUTHENTICATED') {
        ref.read(sessionProvider.notifier).signOut();
        return;
      }
      state = SteveChatState(turns: previous.turns, error: failure);
    } finally {
      if (ref.mounted && generation == _generation) _cancel = null;
    }
  }

  void _scheduleQuotaExpiry(int generation) {
    _quotaTimer?.cancel();
    final quota = state.quota;
    if (quota == null) return;
    final delay = quota.resetAt.difference(
      ref.read(steveClockProvider)().toUtc(),
    );
    _quotaTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!ref.mounted || generation != _generation || state.quota != quota) {
        return;
      }
      state = SteveChatState(
        turns: state.turns,
        pending: state.pending,
        pendingQuestion: state.pendingQuestion,
        error: state.error,
      );
    });
  }
}
