import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/json.dart';
import '../models/user.dart';

/// `/auth/*` and `/me`.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<OtpRequestResult> requestOtp(String phone) async =>
      OtpRequestResult.fromJson(
        asJson(
          await _api.post(
            '/auth/otp/request',
            body: {'phone': phone},
            noAuth: true,
          ),
        ),
      );

  Future<AuthTokens> verifyOtp(String phone, String code) async =>
      AuthTokens.fromJson(
        asJson(
          await _api.post(
            '/auth/otp/verify',
            body: {'phone': phone, 'code': code},
            noAuth: true,
          ),
        ),
      );

  Future<User> me() async => User.fromJson(asJson(await _api.get('/me')));

  Future<User> updateMe({required String name}) async =>
      User.fromJson(asJson(await _api.patch('/me', body: {'name': name})));
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
