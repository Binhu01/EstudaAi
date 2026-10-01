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

class SteveController extends Notifier<SteveChatState> {
  SteveController(this.context);
  final SteveContext context;
  int _generation = 0;
  CancelToken? _cancel;
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
    state = SteveChatState(
      turns: previous.turns,
      quota: previous.quota,
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
        quota: reply.quota,
      );
    } catch (error) {
      if (!_isCurrent() || generation != _generation) return;
      final failure = error is ApiFailure
          ? error
          : const ApiFailure('UNAVAILABLE');
      if (failure.code == 'UNAUTHENTICATED') {
        ref.read(sessionProvider.notifier).signOut();
        return;
      }
      state = SteveChatState(
        turns: previous.turns,
        quota: previous.quota,
        error: failure,
      );
    } finally {
      if (ref.mounted && generation == _generation) _cancel = null;
    }
  }
}
