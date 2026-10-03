import 'dart:math';

import 'package:dio/dio.dart';

import '../../core/api_failure.dart';
import 'study_context_controller.dart';
import 'study_history_api.dart';
import 'study_history_models.dart';

enum SubmissionStatus { idle, sending, confirmed, unconfirmed }

class AnswerSubmissionState {
  const AnswerSubmissionState({
    this.status = SubmissionStatus.idle,
    this.answer,
    this.failure,
  });
  final SubmissionStatus status;
  final ConfirmedAnswer? answer;
  final ApiFailure? failure;
}

String _uuid() {
  final random = Random.secure(),
      bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

class AnswerSubmissionController {
  AnswerSubmissionController({
    required this.api,
    required this.capture,
    required this.stillCurrent,
    this.onChanged,
    this.onConfirmed,
  });
  final StudyHistoryApi Function() api;
  final Future<HistorySnapshot?> Function() capture;
  final bool Function(HistorySnapshot) stillCurrent;
  final void Function(AnswerSubmissionState)? onChanged;
  final void Function(HistorySnapshot)? onConfirmed;
  AnswerSubmissionState state = const AnswerSubmissionState();
  int _generation = 0;
  CancelToken? _cancel;
  String? _id;
  StudyAnswerInput? _input;
  HistorySnapshot? _snapshot;
  void _set(AnswerSubmissionState next) {
    state = next;
    onChanged?.call(next);
  }

  Future<void> submit(StudyAnswerInput input) async {
    if (state.status != SubmissionStatus.idle) return;
    _id = _uuid();
    _input = input;
    await _send(false);
  }

  Future<void> retry() async {
    if (state.status != SubmissionStatus.unconfirmed) return;
    await _send(true);
  }

  Future<void> _send(bool retry) async {
    final generation = _generation, cancel = CancelToken();
    _cancel = cancel;
    _set(const AnswerSubmissionState(status: SubmissionStatus.sending));
    try {
      final snapshot = _snapshot ?? await capture();
      if (generation != _generation) return;
      if (snapshot == null) throw const ApiFailure('UNAUTHENTICATED');
      _snapshot = snapshot;
      bool current() => generation == _generation && stillCurrent(snapshot);
      if (!current()) {
        this.cancel();
        return;
      }
      final answer = await api().confirmAnswer(
        snapshot.context,
        snapshot.goal.scope,
        _id!,
        _input!,
        retry: retry,
        cancelToken: cancel,
        stillCurrent: current,
      );
      if (!current()) return;
      _set(
        AnswerSubmissionState(
          status: SubmissionStatus.confirmed,
          answer: answer,
        ),
      );
      onConfirmed?.call(snapshot);
    } catch (error) {
      if (generation != _generation) return;
      if (_snapshot != null && !stillCurrent(_snapshot!)) {
        this.cancel();
        return;
      }
      _set(
        AnswerSubmissionState(
          status: SubmissionStatus.unconfirmed,
          failure: error is ApiFailure
              ? error
              : const ApiFailure('UNAVAILABLE'),
        ),
      );
    }
  }

  void continueStudy() => cancel();
  void cancel() {
    _generation++;
    _cancel?.cancel();
    _cancel = null;
    _id = null;
    _input = null;
    _snapshot = null;
    _set(const AnswerSubmissionState());
  }
}
