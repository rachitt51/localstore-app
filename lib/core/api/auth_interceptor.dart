import 'package:dio/dio.dart';

import '../models/user.dart';

/// In-memory copy of the current tokens, shared by the session and the
/// interceptor so a refresh done by either is seen by both.
class TokenCache {
  String? accessToken;
  String? refreshToken;

  bool get hasSession => accessToken != null && refreshToken != null;

  void set(AuthTokens tokens) {
    accessToken = tokens.accessToken;
    refreshToken = tokens.refreshToken;
  }

  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}

/// Attaches the bearer token and, on 401, performs a single
/// `POST /auth/refresh` (queued: concurrent failures wait and reuse the new
/// token) then retries the request once. If the refresh fails the session is
/// signed out through [onAuthLost].
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.cache,
    required this.bareDio,
    required this.onTokensRefreshed,
    required this.onAuthLost,
  });

  final TokenCache cache;

  /// A client with no interceptors, used for the refresh call and for the
  /// single retry. Retrying through the intercepted client would queue a
  /// second 401 behind this still-running `onError` (dio serialises
  /// `QueuedInterceptor.onError`) and dead-lock.
  final Dio bareDio;
  final Future<void> Function(AuthTokens tokens) onTokensRefreshed;
  final Future<void> Function() onAuthLost;

  /// Set `extra[noAuthKey] = true` on public calls that must never carry or
  /// refresh a token (login, refresh).
  static const noAuthKey = 'noAuth';
  static const _retriedKey = 'authRetried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra[noAuthKey] != true && cache.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${cache.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final is401 = err.response?.statusCode == 401;
    if (!is401 ||
        options.extra[noAuthKey] == true ||
        options.extra[_retriedKey] == true ||
        !cache.hasSession) {
      return handler.next(err);
    }

    final usedHeader = options.headers['Authorization'];
    final currentHeader = 'Bearer ${cache.accessToken}';
    if (usedHeader != currentHeader) {
      // Another request already refreshed while this one was in flight.
      return _retry(options, handler, err);
    }

    try {
      final response = await bareDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': cache.refreshToken},
      );
      final tokens = AuthTokens.fromJson(response.data!);
      cache.set(tokens);
      await onTokensRefreshed(tokens);
    } catch (_) {
      cache.clear();
      await onAuthLost();
      return handler.next(err);
    }
    return _retry(options, handler, err);
  }

  Future<void> _retry(
    RequestOptions options,
    ErrorInterceptorHandler handler,
    DioException original,
  ) async {
    options.extra[_retriedKey] = true;
    options.headers['Authorization'] = 'Bearer ${cache.accessToken}';
    try {
      final response = await bareDio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(original);
    }
  }
}
