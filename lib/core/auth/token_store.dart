import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The persisted session: both JWTs and the last known user (so the app can
/// start signed in without waiting for `GET /me`).
class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userJson,
  });

  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> userJson;
}

abstract class TokenStore {
  Future<StoredSession?> read();
  Future<void> write(StoredSession session);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _key = 'session';

  @override
  Future<StoredSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return StoredSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        userJson: (json['user'] as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) => _storage.write(
    key: _key,
    value: jsonEncode({
      'accessToken': session.accessToken,
      'refreshToken': session.refreshToken,
      'user': session.userJson,
    }),
  );

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Used in tests and anywhere secure storage is unavailable.
class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this._session]);

  StoredSession? _session;

  @override
  Future<StoredSession?> read() async => _session;

  @override
  Future<void> write(StoredSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());
