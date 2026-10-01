import 'package:dio/dio.dart';

import 'models/user_profile.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.code);
  final String code;
}

class ApiClient {
  ApiClient({required this.baseUrl, required this.token, Dio? dio})
    : dio = dio ?? Dio() {
    final local = {'localhost', '127.0.0.1', '::1'}.contains(baseUrl.host);
    if (!baseUrl.hasAuthority ||
        baseUrl.host.isEmpty ||
        (baseUrl.scheme != 'https' && !(baseUrl.scheme == 'http' && local)) ||
        baseUrl.userInfo.isNotEmpty ||
        baseUrl.hasQuery ||
        baseUrl.hasFragment ||
        (baseUrl.path.isNotEmpty && baseUrl.path != '/')) {
      throw ArgumentError(
        'A API deve usar uma origem HTTPS ou loopback local.',
      );
    }
    this.dio.options = this.dio.options.copyWith(
      connectTimeout: const Duration(seconds: 10),
    );
  }
  final Uri baseUrl;
  final Future<String?> Function() token;
  final Dio dio;
  Future<UserProfile> readMe({CancelToken? cancelToken}) async {
    String? session;
    try {
      session = await token();
    } catch (_) {
      throw const ApiFailure('SESSION_UNAVAILABLE');
    }
    if (session == null ||
        session.isEmpty ||
        session.length > 8192 ||
        session.contains(RegExp(r'\s'))) {
      throw const ApiFailure('UNAUTHENTICATED');
    }
    try {
      final response = await dio.get<Object?>(
        baseUrl.resolve('/v1/me').toString(),
        cancelToken: cancelToken,
        options: Options(
          headers: {'Authorization': 'Bearer $session'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          followRedirects: false,
          responseType: ResponseType.json,
        ),
      );
      final data = response.data;
      if (data is! Map<String, dynamic> ||
          data['id'] is! String ||
          (data['id'] as String).trim().isEmpty ||
          !{'FREE', 'PREMIUM'}.contains(data['plan'])) {
        throw const ApiFailure('INVALID_RESPONSE');
      }
      return UserProfile.fromJson(data);
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) {
        throw const ApiFailure('CANCELLED');
      }
      if (error.response?.statusCode == 401) {
        throw const ApiFailure('UNAUTHENTICATED');
      }
      if (error.response?.statusCode == 429) {
        throw const ApiFailure('RATE_LIMITED');
      }
      if ({
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      }.contains(error.type)) {
        throw const ApiFailure('TIMEOUT');
      }
      throw const ApiFailure('UNAVAILABLE');
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw const ApiFailure('INVALID_RESPONSE');
    }
  }
}
