import '../../core/api_failure.dart';

class AuthSession {
  const AuthSession({
    required this.idToken,
    required this.refreshToken,
    required this.expiresInSeconds,
  });
  final String idToken, refreshToken;
  final int expiresInSeconds;
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final id = json['idToken'],
        refresh = json['refreshToken'],
        expiry = json['expiresInSeconds'];
    if (id is! String ||
        id.isEmpty ||
        id.length > 8192 ||
        !RegExp(r'^[A-Za-z0-9._~-]+$').hasMatch(id) ||
        refresh is! String ||
        refresh.isEmpty ||
        refresh.length > 8192 ||
        RegExp(r'\s').hasMatch(refresh) ||
        expiry is! int ||
        expiry < 1 ||
        expiry > 86400) {
      throw const ApiFailure('INVALID_RESPONSE');
    }
    return AuthSession(
      idToken: id,
      refreshToken: refresh,
      expiresInSeconds: expiry,
    );
  }
}
