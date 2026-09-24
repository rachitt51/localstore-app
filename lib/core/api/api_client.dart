import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../config/app_config.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

final tokenCacheProvider = Provider<TokenCache>((ref) => TokenCache());

BaseOptions _baseOptions() => BaseOptions(
  baseUrl: '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}',
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 15),
  headers: {'Accept': 'application/json'},
);

/// The single [Dio] instance for the app. Features never construct their own;
/// they go through [apiClientProvider].
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  final bareDio = Dio(_baseOptions());
  dio.interceptors.add(
    AuthInterceptor(
      cache: ref.watch(tokenCacheProvider),
      bareDio: bareDio,
      // Read lazily: the session depends on this provider, not the reverse.
      onTokensRefreshed: (tokens) =>
          ref.read(sessionProvider.notifier).tokensRefreshed(tokens),
      onAuthLost: () => ref.read(sessionProvider.notifier).signOut(),
    ),
  );
  ref.onDispose(() {
    dio.close();
    bareDio.close();
  });
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);

/// Thin wrapper that turns every [DioException] into an [ApiException] and
/// returns the decoded body. Repositories are the only callers.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool noAuth = false,
  }) => _run(
    () => _dio.get<dynamic>(
      path,
      queryParameters: _clean(query),
      options: _options(noAuth),
    ),
  );

  Future<dynamic> post(String path, {Object? body, bool noAuth = false}) =>
      _run(
        () => _dio.post<dynamic>(path, data: body, options: _options(noAuth)),
      );

  Future<dynamic> put(String path, {Object? body}) =>
      _run(() => _dio.put<dynamic>(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _run(() => _dio.patch<dynamic>(path, data: body));

  Future<dynamic> delete(String path) => _run(() => _dio.delete<dynamic>(path));

  /// Multipart upload; the API expects the field to be called `file`.
  Future<dynamic> upload(String path, String filePath, {String? fileName}) =>
      _run(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: fileName),
        });
        return _dio.post<dynamic>(path, data: form);
      });

  Options? _options(bool noAuth) =>
      noAuth ? Options(extra: {AuthInterceptor.noAuthKey: true}) : null;

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final out = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      out[key] = value;
    });
    return out.isEmpty ? null : out;
  }

  Future<dynamic> _run(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
