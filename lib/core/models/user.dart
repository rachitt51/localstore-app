import 'json.dart';

class User {
  const User({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
  });

  factory User.fromJson(Json json) => User(
    id: asString(json['id']),
    phone: asString(json['phone']),
    name: asStringOrNull(json['name']),
    role: asString(json['role'], 'CUSTOMER'),
  );

  final String id;
  final String phone;
  final String? name;

  /// `OWNER`, `STAFF` or `CUSTOMER`.
  final String role;

  bool get isStaff => role == 'OWNER' || role == 'STAFF';

  String get displayName =>
      (name == null || name!.trim().isEmpty) ? phone : name!;

  Json toJson() => {'id': id, 'phone': phone, 'name': name, 'role': role};

  User copyWith({String? name}) =>
      User(id: id, phone: phone, name: name ?? this.name, role: role);
}

/// `POST /auth/otp/verify` and `POST /auth/refresh` response.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthTokens.fromJson(Json json) => AuthTokens(
    accessToken: asString(json['accessToken']),
    refreshToken: asString(json['refreshToken']),
    user: User.fromJson(asJson(json['user'])),
  );

  final String accessToken;
  final String refreshToken;
  final User user;
}

/// `POST /auth/otp/request` response.
class OtpRequestResult {
  const OtpRequestResult({required this.expiresInSec, this.devCode});

  factory OtpRequestResult.fromJson(Json json) => OtpRequestResult(
    expiresInSec: asInt(json['expiresInSec'], 300),
    devCode: asStringOrNull(json['devCode']),
  );

  final int expiresInSec;

  /// Present only when the API runs with `OTP_PROVIDER=console`.
  final String? devCode;
}
