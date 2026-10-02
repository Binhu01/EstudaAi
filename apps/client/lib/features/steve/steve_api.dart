import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_failure.dart';
import '../../core/api_origin.dart';
import '../auth/session_controller.dart';
import '../learning/learning_controller.dart';
import '../learning/learning_catalog_providers.dart';
import '../learning/study_catalog.dart';
import 'steve_models.dart';

final steveApiProvider = Provider<SteveApi>((ref) {
  ref.watch(learningEntryProvider(ref.watch(learningProvider).topicId));
  return SteveApi(
    baseUrl: ref.watch(apiOriginProvider),
    dio: ref.watch(dioProvider),
    findTopic: (id) => ref.read(learningEntryProvider(id)).asData?.value?.topic,
    token: ref.read(sessionProvider.notifier).accessToken,
  );
});

class SteveApi {
  SteveApi({
    required Uri baseUrl,
    required this.token,
    required this.findTopic,
    Dio? dio,
  }) : baseUrl = validateApiOrigin(baseUrl),
       dio = dio ?? Dio();
  final Uri baseUrl;
  final Dio dio;
  final Future<String?> Function() token;
  final StudyTopic? Function(String) findTopic;
  Future<SteveReply> send({
    required String topicId,
    required String message,
    required List<ChatMessage> history,
    required CancelToken cancelToken,
  }) async {
    final topic = findTopic(topicId);
    if (topic == null || message.trim().isEmpty || message.length > 2000) {
      throw const ApiFailure('INVALID_INPUT');
    }
    final bearer = await token();
    if (bearer == null ||
        !RegExp(r'^[A-Za-z0-9._~-]{1,8192}$').hasMatch(bearer)) {
      throw const ApiFailure('UNAUTHENTICATED');
    }
    try {
      final response = await dio.post<Object?>(
        baseUrl.resolve('/v1/steve/messages').toString(),
        data: {
          'topicId': topicId,
          'message': message,
          'history': boundedHistory(history).map((m) => m.toJson()).toList(),
        },
        cancelToken: cancelToken,
        options: Options(
          headers: {'Authorization': 'Bearer $bearer'},
          followRedirects: false,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const ApiFailure('INVALID_RESPONSE');
      }
      return SteveReply.fromJson(body, topic: topic);
    } on DioException catch (error) {
      throw apiFailure(error);
    }
  }
}
