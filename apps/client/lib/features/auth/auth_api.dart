import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_failure.dart';
import '../../core/api_origin.dart';
import 'auth_models.dart';

final authApiProvider = Provider<AuthApi>(
  (ref) =>
      AuthApi(baseUrl: ref.read(apiOriginProvider), dio: ref.read(dioProvider)),
);

class AuthApi {
  AuthApi({required Uri baseUrl, Dio? dio})
    : baseUrl = validateApiOrigin(baseUrl),
      dio =
          dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
  final Uri baseUrl;
  final Dio dio;
  Future<Map<String, dynamic>> _post(
    String route,
    Map<String, Object> body,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await dio.post<Object?>(
        baseUrl.resolve('/v1/auth/$route').toString(),
        data: body,
        cancelToken: cancelToken,
        options: Options(
          followRedirects: false,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          responseType: ResponseType.json,
        ),
      );
      if (response.data is! Map<String, dynamic>) {
        throw const ApiFailure('INVALID_RESPONSE');
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      throw apiFailure(error);
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw const ApiFailure('INVALID_RESPONSE');
    }
  }

  Future<AuthSession> login(
    String email,
    String password, {
    CancelToken? cancelToken,
  }) async => AuthSession.fromJson(
    await _post('login', {
      'email': email.trim(),
      'password': password,
    }, cancelToken),
  );
  Future<AuthSession> register(
    String email,
    String password, {
    CancelToken? cancelToken,
  }) async => AuthSession.fromJson(
    await _post('register', {
      'email': email.trim(),
      'password': password,
    }, cancelToken),
  );
  Future<AuthSession> refresh(String token, {CancelToken? cancelToken}) async =>
      AuthSession.fromJson(
        await _post('refresh', {'refreshToken': token}, cancelToken),
      );
  Future<void> resetPassword(String email, {CancelToken? cancelToken}) async {
    final response = await _post('password-reset', {
      'email': email.trim(),
    }, cancelToken);
    if (response['accepted'] != true) {
      throw const ApiFailure('INVALID_RESPONSE');
    }
  }
}
