import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../api/api_client.dart';
import '../api/auth_interceptor.dart';
import '../auth/session.dart';
import '../config/app_config.dart';
import '../models/json.dart';
import '../models/order_updated_event.dart';

/// Socket.IO channel from `demo-v0.md` (Realtime): path `/ws`, namespace
/// `/orders`, handshake `auth: {token}`, server → client `order.updated`.
/// Events are signals only; screens re-fetch what they show.

enum RealtimeStatus {
  /// No connection wanted (signed out).
  off,

  /// Wanted but not established: first attempt or auto-reconnect in flight.
  connecting,
  connected,
}

/// What [RealtimeService] asks the socket factory for.
@immutable
class RealtimeSocketConfig {
  const RealtimeSocketConfig({
    required this.uri,
    required this.path,
    required this.token,
  });

  /// `<apiBaseUrl>/orders` — the namespace is the URI path.
  final String uri;

  /// `/ws`.
  final String path;
  final String token;

  @override
  bool operator ==(Object other) =>
      other is RealtimeSocketConfig &&
      other.uri == uri &&
      other.path == path &&
      other.token == token;

  @override
  int get hashCode => Object.hash(uri, path, token);
}

/// The slice of a Socket.IO client the service uses, so tests can inject a
/// fake with no network.
abstract class RealtimeSocket {
  void onConnect(void Function() handler);
  void onDisconnect(void Function() handler);
  void onConnectError(void Function(Object? error) handler);
  void onEvent(String event, void Function(Object? data) handler);
  void connect();

  /// Disconnect, stop reconnecting and drop every listener.
  void dispose();
}

typedef RealtimeSocketFactory = RealtimeSocket Function(
  RealtimeSocketConfig config,
);

/// Production socket: websocket transport only, auto-reconnect with backoff,
/// one Manager per connection (`forceNew`) so a token change never reuses a
/// cached engine.
class SocketIoRealtimeSocket implements RealtimeSocket {
  SocketIoRealtimeSocket(RealtimeSocketConfig config)
    : _socket = sio.io(
        config.uri,
        sio.OptionBuilder()
            .setPath(config.path)
            .setTransports(const ['websocket'])
            .setAuth({'token': config.token})
            .enableForceNew()
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(10000)
            .build(),
      );

  final sio.Socket _socket;

  @override
  void onConnect(void Function() handler) =>
      _socket.onConnect((_) => handler());

  @override
  void onDisconnect(void Function() handler) =>
      _socket.onDisconnect((_) => handler());

  @override
  void onConnectError(void Function(Object? error) handler) =>
      _socket.onConnectError(handler);

  @override
  void onEvent(String event, void Function(Object? data) handler) =>
      _socket.on(event, handler);

  @override
  void connect() => _socket.connect();

  @override
  void dispose() => _socket.dispose();
}

/// Owns the single socket for the app. Connected while a session is signed
/// in ([realtimeServiceProvider] drives it from [sessionProvider]); rebuilt
/// with the new access token after a refresh.
class RealtimeService {
  RealtimeService({
    required this.tokens,
    required this.socketFactory,
    this.baseUrl = AppConfig.apiBaseUrl,
  });

  static const namespace = '/orders';
  static const socketPath = '/ws';
  static const orderUpdatedEvent = 'order.updated';

  final TokenCache tokens;
  final RealtimeSocketFactory socketFactory;
  final String baseUrl;

  final _events = StreamController<OrderUpdatedEvent>.broadcast();
  final status = ValueNotifier<RealtimeStatus>(RealtimeStatus.off);

  RealtimeSocket? _socket;
  RealtimeSocketConfig? _config;
  bool _disposed = false;

  /// Every `order.updated` the server sends this user (own orders, plus all
  /// orders for OWNER/STAFF).
  Stream<OrderUpdatedEvent> get events => _events.stream;

  bool get connected => status.value == RealtimeStatus.connected;

  /// The config of the live socket, or null when disconnected.
  RealtimeSocketConfig? get currentConfig => _config;

  /// Open a socket with the current access token. No-op when one is already
  /// open with that token; replaces the socket when the token changed;
  /// disconnects when there is no token.
  void connect() {
    if (_disposed) return;
    final token = tokens.accessToken;
    if (token == null) {
      disconnect();
      return;
    }
    final config = RealtimeSocketConfig(
      uri: '$baseUrl$namespace',
      path: socketPath,
      token: token,
    );
    if (_socket != null && _config == config) return;
    _open(config);
  }

  /// Drop the current socket and open a fresh one with the current token.
  void reconnect() {
    if (_disposed) return;
    disconnect();
    connect();
  }

  void disconnect() {
    final socket = _socket;
    _socket = null;
    _config = null;
    socket?.dispose();
    if (!_disposed) status.value = RealtimeStatus.off;
  }

  void dispose() {
    if (_disposed) return;
    disconnect();
    _disposed = true;
    _events.close();
    status.dispose();
  }

  void _open(RealtimeSocketConfig config) {
    disconnect();
    final socket = socketFactory(config);
    _socket = socket;
    _config = config;
    status.value = RealtimeStatus.connecting;
    // Guard every callback: a socket we already replaced must not touch state.
    bool live() => identical(_socket, socket) && !_disposed;
    socket.onConnect(() {
      _log('connected ${config.uri} (path ${config.path})');
      if (live()) status.value = RealtimeStatus.connected;
    });
    socket.onDisconnect(() {
      _log('disconnected');
      if (live()) status.value = RealtimeStatus.connecting;
    });
    socket.onConnectError((error) {
      _log('connect error: $error');
      if (live()) status.value = RealtimeStatus.connecting;
    });
    socket.onEvent(orderUpdatedEvent, (data) {
      if (!live()) return;
      final event = _parse(data);
      if (event != null) _events.add(event);
    });
    socket.connect();
  }

  // Debug-build breadcrumbs (visible in `adb logcat -s flutter`); the socket
  // library itself is silent, so this is the only trace of the handshake.
  static void _log(String message) {
    if (kDebugMode) debugPrint('[realtime] $message');
  }

  static OrderUpdatedEvent? _parse(Object? data) {
    try {
      return OrderUpdatedEvent.fromJson(asJson(data));
    } catch (_) {
      // Not the documented shape; ignore rather than crash a screen.
      return null;
    }
  }
}

/// Override in tests to inject a fake socket.
final realtimeSocketFactoryProvider = Provider<RealtimeSocketFactory>(
  (_) => SocketIoRealtimeSocket.new,
);

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(
    tokens: ref.watch(tokenCacheProvider),
    socketFactory: ref.watch(realtimeSocketFactoryProvider),
  );
  ref.onDispose(service.dispose);
  ref.listen(sessionProvider, (_, session) {
    if (session.isSignedIn) {
      service.connect();
    } else {
      service.disconnect();
    }
  }, fireImmediately: true);
  ref.listen(tokenGenerationProvider, (_, _) {
    if (ref.read(sessionProvider).isSignedIn) service.reconnect();
  });
  return service;
});

/// `order.updated` as a provider so notifiers can `ref.listen` to it.
final orderUpdatesProvider = StreamProvider<OrderUpdatedEvent>(
  (ref) => ref.watch(realtimeServiceProvider).events,
);

class RealtimeStatusNotifier extends Notifier<RealtimeStatus> {
  @override
  RealtimeStatus build() {
    final status = ref.watch(realtimeServiceProvider).status;
    void changed() => state = status.value;
    status.addListener(changed);
    ref.onDispose(() => status.removeListener(changed));
    return status.value;
  }
}

final realtimeStatusProvider =
    NotifierProvider<RealtimeStatusNotifier, RealtimeStatus>(
      RealtimeStatusNotifier.new,
    );

/// True while the socket is up; drives the "Live" indicator.
final realtimeConnectedProvider = Provider<bool>(
  (ref) => ref.watch(realtimeStatusProvider) == RealtimeStatus.connected,
);
