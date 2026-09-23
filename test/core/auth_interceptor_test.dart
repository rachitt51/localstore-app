import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localstore_app/core/api/auth_interceptor.dart';
import 'package:localstore_app/core/models/user.dart';

/// Scripted HTTP layer: records every request and answers by path/token.
class FakeAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  var validToken = 'access-1';
  var refreshShouldFail = false;
  var refreshCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path == '/auth/refresh') {
      refreshCalls++;
      if (refreshShouldFail) {
        return _json(401, {
          'statusCode': 401,
          'code': 'TOKEN_REUSED',
          'message': 'Refresh token was already used',
        });
      }
      validToken = 'access-${refreshCalls + 1}';
      return _json(200, {
        'accessToken': validToken,
        'refreshToken': 'refresh-${refreshCalls + 1}',
        'user': {
          'id': 'u1',
          'phone': '+919999999990',
          'name': 'S',
          'role': 'CUSTOMER',
        },
      });
    }
    if (options.path.startsWith('/auth/')) {
      return _json(200, {'ok': true, 'public': true});
    }
    if (options.headers['Authorization'] != 'Bearer $validToken') {
      return _json(401, {
        'statusCode': 401,
        'code': 'UNAUTHORIZED',
        'message': 'Unauthorized',
      });
    }
    return _json(200, {'ok': true, 'path': options.path});
  }

  ResponseBody _json(int status, Map<String, dynamic> body) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeAdapter adapter;
  late TokenCache cache;
  late Dio dio;
  late List<AuthTokens> refreshed;
  late int authLost;

  setUp(() {
    adapter = FakeAdapter();
    cache = TokenCache()
      ..accessToken = 'stale'
      ..refreshToken = 'refresh-1';
    refreshed = [];
    authLost = 0;
    final options = BaseOptions(baseUrl: 'http://api.test/v1');
    final bare = Dio(options)..httpClientAdapter = adapter;
    dio = Dio(options)..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        cache: cache,
        bareDio: bare,
        onTokensRefreshed: (t) async => refreshed.add(t),
        onAuthLost: () async => authLost++,
      ),
    );
  });

  test('attaches the bearer token', () async {
    cache.accessToken = 'access-1';
    await dio.get<dynamic>('/me');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer access-1');
  });

  test('public calls carry no token', () async {
    cache.accessToken = 'access-1';
    await dio.post<dynamic>(
      '/auth/otp/request',
      options: Options(extra: {AuthInterceptor.noAuthKey: true}),
    );
    expect(adapter.requests.single.headers.containsKey('Authorization'), false);
    expect(adapter.refreshCalls, 0);
  });

  test('on 401 refreshes once and retries with the new token', () async {
    final response = await dio.get<Map<String, dynamic>>('/me');
    expect(response.data?['ok'], true);
    expect(adapter.refreshCalls, 1);
    expect(cache.accessToken, 'access-2');
    expect(cache.refreshToken, 'refresh-2');
    expect(refreshed.single.accessToken, 'access-2');
    expect(authLost, 0);
    expect(adapter.requests.map((r) => r.path), [
      '/me',
      '/auth/refresh',
      '/me',
    ]);
    expect(adapter.requests.last.headers['Authorization'], 'Bearer access-2');
  });

  test('concurrent 401s share a single refresh', () async {
    final results = await Future.wait([
      dio.get<Map<String, dynamic>>('/cart'),
      dio.get<Map<String, dynamic>>('/orders'),
      dio.get<Map<String, dynamic>>('/me/addresses'),
    ]);
    expect(results.every((r) => r.data?['ok'] == true), isTrue);
    expect(adapter.refreshCalls, 1);
    expect(refreshed, hasLength(1));
    final retries = adapter.requests
        .where((r) => r.headers['Authorization'] == 'Bearer access-2')
        .map((r) => r.path);
    expect(retries, containsAll(['/cart', '/orders', '/me/addresses']));
  });

  test('refresh failure signs out and surfaces the original 401', () async {
    adapter.refreshShouldFail = true;
    await expectLater(
      dio.get<dynamic>('/me'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(adapter.refreshCalls, 1);
    expect(authLost, 1);
    expect(cache.hasSession, isFalse);
    expect(refreshed, isEmpty);
  });

  test('a 401 with no session is passed through untouched', () async {
    cache.clear();
    await expectLater(dio.get<dynamic>('/me'), throwsA(isA<DioException>()));
    expect(adapter.refreshCalls, 0);
    expect(authLost, 0);
  });
}
