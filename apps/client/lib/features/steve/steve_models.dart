import '../../core/api_failure.dart';
import '../learning/study_catalog.dart';

class ChatMessage {
  const ChatMessage(this.role, this.text);
  final String role, text;
  Map<String, String> toJson() => {'role': role, 'text': text};
}

// Keep complete exchanges: neither truncated answers nor orphan messages.
List<ChatMessage> boundedHistory(List<ChatMessage> messages) {
  final pairs = <List<ChatMessage>>[];
  for (var i = 0; i + 1 < messages.length; i += 2) {
    final user = messages[i], assistant = messages[i + 1];
    if (user.role == 'user' &&
        assistant.role == 'assistant' &&
        user.text.trim().isNotEmpty &&
        assistant.text.trim().isNotEmpty &&
        user.text.length <= 2000 &&
        assistant.text.length <= 2000) {
      pairs.add([user, assistant]);
    }
  }
  while (pairs.length > 4 ||
      pairs.expand((p) => p).fold<int>(0, (n, m) => n + m.text.length) >
          12000) {
    pairs.removeAt(0);
  }
  return List.unmodifiable(pairs.expand((p) => p));
}

class SteveQuota {
  const SteveQuota(this.remaining, this.resetAt);
  final int remaining;
  final DateTime resetAt;
}

class SteveReply {
  const SteveReply({
    required this.topicId,
    required this.status,
    required this.text,
    required this.sources,
    required this.quota,
    required this.requestId,
  });
  final String topicId, status, text, requestId;
  final List<StudySource> sources;
  final SteveQuota quota;
  factory SteveReply.fromJson(
    Map<String, dynamic> json, {
    required StudyTopic topic,
  }) {
    Never invalid() => throw const ApiFailure('INVALID_RESPONSE');
    final status = json['status'], text = json['text'], id = json['requestId'];
    final quota = json['quota'], sources = json['sources'];
    if (json['topicId'] != topic.id ||
        !{'completed', 'refused', 'incomplete'}.contains(status) ||
        text is! String ||
        text.length > 16000 ||
        (status != 'incomplete' && text.trim().isEmpty) ||
        id is! String ||
        !RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')
            .hasMatch(id) ||
        quota is! Map ||
        quota['remaining'] is! int ||
        quota['remaining'] < 0 ||
        quota['remaining'] > 1000 ||
        quota['resetAt'] is! String ||
        sources is! List) {
      invalid();
    }
    final resetText = quota['resetAt'] as String;
    final reset = DateTime.tryParse(resetText);
    if (reset == null ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$')
            .hasMatch(resetText)) {
      invalid();
    }
    final verified = <StudySource>[];
    for (final item in sources) {
      if (item is! Map) invalid();
      final matches = topic.sources.where(
        (s) => s.url == item['url'] && s.title == item['title'],
      );
      if (matches.length != 1 || verified.any((s) => s.url == item['url'])) {
        invalid();
      }
      verified.add(matches.single);
    }
    return SteveReply(
      topicId: topic.id,
      status: status as String,
      text: text,
      sources: List.unmodifiable(verified),
      quota: SteveQuota(quota['remaining'] as int, reset.toUtc()),
      requestId: id,
    );
  }
}

class ChatTurn {
  const ChatTurn(this.question, this.reply);
  final String question;
  final SteveReply reply;
}

class SteveChatState {
  const SteveChatState({
    this.turns = const [],
    this.pending = false,
    this.pendingQuestion,
    this.error,
    this.quota,
  });
  final List<ChatTurn> turns;
  final bool pending;
  final String? pendingQuestion;
  final ApiFailure? error;
  final SteveQuota? quota;
  List<ChatMessage> get messages => List.unmodifiable([
    for (final turn in turns) ...[
      ChatMessage('user', turn.question),
      ChatMessage('assistant', turn.reply.text),
    ],
  ]);
  List<ChatMessage> get history => boundedHistory([
    for (final turn in turns.where((t) => t.reply.status == 'completed')) ...[
      ChatMessage('user', turn.question),
      ChatMessage('assistant', turn.reply.text),
    ],
  ]);
}
