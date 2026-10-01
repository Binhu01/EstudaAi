import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_origin.dart';
import '../../core/models/user_profile.dart';
import 'auth_api.dart';
import 'auth_models.dart';

enum SessionStatus {
  signedOut,
  authenticating,
  authenticated,
  refreshUnavailable,
}

class SessionState {
  const SessionState({
    this.status = SessionStatus.signedOut,
    this.profile,
    this.error,
    this.generation = 0,
  });
  final SessionStatus status;
  final UserProfile? profile;
  final ApiFailure? error;
  final int generation;
  bool get isAuthenticated =>
      profile != null &&
      (status == SessionStatus.authenticated ||
          status == SessionStatus.refreshUnavailable);
}

final sessionClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionController extends Notifier<SessionState> {
  AuthSession? _credentials;
  DateTime? _expiresAt;
  CancelToken? _authCancel, _refreshCancel, _profileCancel;
  Future<String?>? _refreshing;
  int _generation = 0;
  bool _busy = false;
  DateTime get _now => ref.read(sessionClockProvider)().toUtc();
  @override
  SessionState build() {
    ref.onDispose(() {
      _authCancel?.cancel();
      _refreshCancel?.cancel();
      _profileCancel?.cancel();
    });
    return const SessionState();
  }

  void signOut() {
    _generation++;
    _authCancel?.cancel();
    _refreshCancel?.cancel();
    _profileCancel?.cancel();
    _credentials = null;
    _expiresAt = null;
    _refreshing = null;
    _busy = false;
    state = SessionState(generation: _generation);
  }

  Future<void> login(String email, String password) => _authenticate(
    (api, cancel) => api.login(email, password, cancelToken: cancel),
  );
  Future<void> register(String email, String password) => _authenticate(
    (api, cancel) => api.register(email, password, cancelToken: cancel),
  );
  Future<void> _authenticate(
    Future<AuthSession> Function(AuthApi, CancelToken) request,
  ) async {
    if (_busy) {
      return;
    }
    signOut();
    _busy = true;
    final generation = _generation, cancel = CancelToken();
    _authCancel = cancel;
    state = SessionState(
      status: SessionStatus.authenticating,
      generation: generation,
    );
    try {
      final credentials = await request(ref.read(authApiProvider), cancel);
      if (!ref.mounted || generation != _generation) {
        return;
      }
      _credentials = credentials;
      _expiresAt = _now.add(Duration(seconds: credentials.expiresInSeconds));
      await _loadProfile(generation);
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        _setFailure(error);
      }
    } finally {
      if (ref.mounted && generation == _generation) {
        _busy = false;
      }
    }
  }

  void _setFailure(Object error) {
    final failure = error is ApiFailure
        ? error
        : const ApiFailure('UNAVAILABLE');
    if (failure.code == 'UNAUTHENTICATED' || _credentials == null) {
      signOut();
      state = SessionState(error: failure, generation: _generation);
    } else {
      state = SessionState(
        status: SessionStatus.refreshUnavailable,
        profile: state.profile,
        error: failure,
        generation: _generation,
      );
    }
  }

  Future<void> _loadProfile(int generation) async {
    final token = await _tokenOrRefresh();
    if (!ref.mounted || generation != _generation || token == null) {
      return;
    }
    final cancel = CancelToken();
    _profileCancel = cancel;
    final profile = await ApiClient(
      baseUrl: ref.read(apiOriginProvider),
      token: () async => token,
      dio: ref.read(dioProvider),
    ).readMe(cancelToken: cancel);
    if (ref.mounted && generation == _generation) {
      state = SessionState(
        status: SessionStatus.authenticated,
        profile: profile,
        generation: generation,
      );
    }
  }

  Future<void> retryProfile() async {
    if (_credentials == null || _busy) {
      return;
    }
    _busy = true;
    final generation = _generation;
    try {
      await _loadProfile(generation);
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        _setFailure(error);
      }
    } finally {
      if (ref.mounted && generation == _generation) {
        _busy = false;
      }
    }
  }

  Future<String?> accessToken() async {
    final token = await _tokenOrRefresh();
    return ref.mounted && state.isAuthenticated ? token : null;
  }

  Future<String?> _tokenOrRefresh() {
    final credentials = _credentials, expires = _expiresAt;
    if (credentials == null || expires == null) {
      return Future.value(null);
    }
    if (_now.isBefore(expires.subtract(const Duration(seconds: 30)))) {
      return Future.value(credentials.idToken);
    }
    if (_refreshing != null) {
      return _refreshing!;
    }
    final generation = _generation;
    final cancel = CancelToken();
    _refreshCancel = cancel;
    late Future<String?> operation;
    operation = _renew(credentials, generation, cancel).whenComplete(() {
      if (identical(_refreshing, operation)) {
        _refreshing = null;
      }
    });
    _refreshing = operation;
    return operation;
  }

  Future<String?> _renew(
    AuthSession original,
    int generation,
    CancelToken cancel,
  ) async {
    try {
      final next = await ref
          .read(authApiProvider)
          .refresh(original.refreshToken, cancelToken: cancel);
      if (!ref.mounted ||
          generation != _generation ||
          !identical(original, _credentials)) {
        return null;
      }
      _credentials = next;
      _expiresAt = _now.add(Duration(seconds: next.expiresInSeconds));
      state = SessionState(
        status: state.profile != null
            ? SessionStatus.authenticated
            : SessionStatus.refreshUnavailable,
        profile: state.profile,
        generation: generation,
      );
      return next.idToken;
    } catch (error) {
      if (!ref.mounted || generation != _generation) {
        return null;
      }
      final failure = error is ApiFailure
          ? error
          : const ApiFailure('UNAVAILABLE');
      if (failure.code == 'UNAUTHENTICATED') {
        _setFailure(failure);
        return null;
      }
      state = SessionState(
        status: SessionStatus.refreshUnavailable,
        profile: state.profile,
        error: failure,
        generation: generation,
      );
      if (_expiresAt != null && _now.isBefore(_expiresAt!)) {
        return original.idToken;
      }
      throw const ApiFailure('SESSION_UNAVAILABLE');
    }
  }

  Future<void> resetPassword(String email) async {
    if (_busy) {
      return;
    }
    _busy = true;
    final generation = _generation, cancel = CancelToken();
    _authCancel = cancel;
    state = SessionState(
      status: SessionStatus.authenticating,
      generation: generation,
    );
    try {
      await ref.read(authApiProvider).resetPassword(email, cancelToken: cancel);
      if (ref.mounted && generation == _generation) {
        state = SessionState(generation: generation);
      }
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        _setFailure(error);
      }
    } finally {
      if (ref.mounted && generation == _generation) {
        _busy = false;
      }
    }
  }
}
