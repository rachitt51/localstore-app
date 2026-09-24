import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/auth_interceptor.dart';
import '../models/user.dart';
import 'auth_repository.dart';
import 'token_store.dart';

enum SessionStatus { unknown, guest, signedIn }

class SessionState {
  const SessionState._(this.status, this.user);

  const SessionState.unknown() : this._(SessionStatus.unknown, null);
  const SessionState.guest() : this._(SessionStatus.guest, null);
  const SessionState.signedIn(User user) : this._(SessionStatus.signedIn, user);

  final SessionStatus status;
  final User? user;

  bool get isSignedIn => status == SessionStatus.signedIn;
  bool get isGuest => status == SessionStatus.guest;
  bool get isUnknown => status == SessionStatus.unknown;
  bool get isStaff => user?.isStaff ?? false;

  @override
  bool operator ==(Object other) =>
      other is SessionState &&
      other.status == status &&
      other.user?.id == user?.id &&
      other.user?.name == user?.name &&
      other.user?.role == user?.role;

  @override
  int get hashCode => Object.hash(status, user?.id, user?.name, user?.role);
}

/// Who is signed in. Tokens live in [TokenStore] (secure storage) and are
/// mirrored into [TokenCache] for the dio interceptor.
class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState.unknown();

  TokenStore get _store => ref.read(tokenStoreProvider);
  TokenCache get _cache => ref.read(tokenCacheProvider);
  AuthRepository get _auth => ref.read(authRepositoryProvider);

  /// Called once at startup (awaited in `main`). Restores the cached user
  /// immediately, then refreshes it from `GET /me` in the background.
  Future<void> restore() async {
    final stored = await _store.read();
    if (stored == null) {
      state = const SessionState.guest();
      return;
    }
    _cache
      ..accessToken = stored.accessToken
      ..refreshToken = stored.refreshToken;
    state = SessionState.signedIn(User.fromJson(stored.userJson));
    // Fire and forget; a 401 here signs out through the interceptor.
    refreshUser();
  }

  Future<void> refreshUser() async {
    if (!state.isSignedIn) return;
    try {
      final user = await _auth.me();
      if (state.isSignedIn) await _setUser(user);
    } on ApiException catch (_) {
      // Network or a 401 already handled by the interceptor; keep going.
    }
  }

  Future<void> signIn(AuthTokens tokens) async {
    _cache.set(tokens);
    await _persist(tokens.user);
    state = SessionState.signedIn(tokens.user);
  }

  /// The interceptor rotated the tokens; persist them with the current user
  /// and tell token-bound connections (the realtime socket) to reconnect.
  Future<void> tokensRefreshed(AuthTokens tokens) async {
    _cache.set(tokens);
    await _persist(state.user ?? tokens.user);
    ref.read(tokenGenerationProvider.notifier).bump();
  }

  Future<void> updateName(String name) async {
    final user = await _auth.updateMe(name: name);
    await _setUser(user);
  }

  Future<void> signOut() async {
    _cache.clear();
    await _store.clear();
    state = const SessionState.guest();
  }

  Future<void> _setUser(User user) async {
    await _persist(user);
    state = SessionState.signedIn(user);
  }

  Future<void> _persist(User user) async {
    final access = _cache.accessToken;
    final refresh = _cache.refreshToken;
    if (access == null || refresh == null) return;
    await _store.write(
      StoredSession(
        accessToken: access,
        refreshToken: refresh,
        userJson: user.toJson(),
      ),
    );
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

/// Counts token rotations ([SessionNotifier.tokensRefreshed]). The session
/// state itself does not change on a refresh (same user), so anything that
/// holds a connection authenticated with the access token listens to this.
class TokenGenerationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final tokenGenerationProvider = NotifierProvider<TokenGenerationNotifier, int>(
  TokenGenerationNotifier.new,
);
