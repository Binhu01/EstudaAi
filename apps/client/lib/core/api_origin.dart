import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_failure.dart';

const _loopback = {'localhost', '127.0.0.1', '::1'};
Uri validateApiOrigin(Uri url) {
  if (!url.hasAuthority ||
      url.host.isEmpty ||
      (url.scheme != 'https' &&
          !(url.scheme == 'http' && _loopback.contains(url.host))) ||
      url.userInfo.isNotEmpty ||
      url.hasQuery ||
      url.hasFragment ||
      (url.path.isNotEmpty && url.path != '/')) {
    throw ArgumentError('A API deve usar uma origem HTTPS ou loopback local.');
  }
  return url;
}

final apiOriginProvider = Provider<Uri>((ref) {
  const origin = String.fromEnvironment('API_ORIGIN');
  if (origin.isNotEmpty) {
    return validateApiOrigin(Uri.parse(origin));
  }
  if (!kReleaseMode || _loopback.contains(Uri.base.host)) {
    return Uri.parse('http://127.0.0.1:3001');
  }
  throw const ApiFailure('UNAVAILABLE');
});
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
  ref.onDispose(() => dio.close(force: true));
  return dio;
});
