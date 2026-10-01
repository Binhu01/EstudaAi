import 'package:dio/dio.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.code, {this.resetAt});
  final String code;
  final DateTime? resetAt;
}

ApiFailure apiFailure(DioException error) {
  if (error.type == DioExceptionType.cancel) {
    return const ApiFailure('CANCELLED');
  }
  final status = error.response?.statusCode;
  if (status == 400) {
    return const ApiFailure('INVALID_INPUT');
  }
  if (status == 401) {
    return const ApiFailure('UNAUTHENTICATED');
  }
  if (status == 413) {
    return const ApiFailure('PAYLOAD_TOO_LARGE');
  }
  if (status == 429) {
    final body = error.response?.data;
    final reset = body is Map && body['resetAt'] is String
        ? DateTime.tryParse(body['resetAt'] as String)
        : null;
    return ApiFailure(
      reset != null ? 'DAILY_LIMIT' : 'RATE_LIMITED',
      resetAt: reset,
    );
  }
  if ({
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
  }.contains(error.type)) {
    return const ApiFailure('TIMEOUT');
  }
  return const ApiFailure('UNAVAILABLE');
}

String safeFailureMessage(String? code) => switch (code) {
  'INVALID_INPUT' => 'Confira os dados e tente novamente.',
  'UNAUTHENTICATED' =>
    'Não foi possível validar o acesso. Entre novamente ou confira os dados.',
  'RATE_LIMITED' => 'Aguarde um momento antes de tentar novamente.',
  'DAILY_LIMIT' =>
    'O limite diário do Steve foi atingido. Volte após a renovação da cota.',
  'TIMEOUT' => 'A resposta demorou. Tente novamente em um momento.',
  'PAYLOAD_TOO_LARGE' => 'Reduza o tamanho da mensagem e tente novamente.',
  'INVALID_RESPONSE' =>
    'Não foi possível confirmar a resposta. Tente novamente.',
  _ => 'O serviço está indisponível no momento. Tente novamente mais tarde.',
};
