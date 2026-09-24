import 'package:localstore_app/core/realtime/realtime.dart';

/// No-network stand-in for the Socket.IO client. Tests drive it with
/// [emitConnect], [emitDisconnect], [emitConnectError] and [emitEvent].
class FakeRealtimeSocket implements RealtimeSocket {
  FakeRealtimeSocket(this.config);

  final RealtimeSocketConfig config;
  bool connectCalled = false;
  bool disposed = false;

  final _connect = <void Function()>[];
  final _disconnect = <void Function()>[];
  final _connectError = <void Function(Object?)>[];
  final _events = <String, List<void Function(Object?)>>{};

  @override
  void onConnect(void Function() handler) => _connect.add(handler);

  @override
  void onDisconnect(void Function() handler) => _disconnect.add(handler);

  @override
  void onConnectError(void Function(Object? error) handler) =>
      _connectError.add(handler);

  @override
  void onEvent(String event, void Function(Object? data) handler) =>
      _events.putIfAbsent(event, () => []).add(handler);

  @override
  void connect() => connectCalled = true;

  @override
  void dispose() {
    disposed = true;
    _connect.clear();
    _disconnect.clear();
    _connectError.clear();
    _events.clear();
  }

  void emitConnect() {
    for (final h in List.of(_connect)) {
      h();
    }
  }

  void emitDisconnect() {
    for (final h in List.of(_disconnect)) {
      h();
    }
  }

  void emitConnectError([Object? error]) {
    for (final h in List.of(_connectError)) {
      h(error);
    }
  }

  void emitEvent(String event, Object? data) {
    for (final h in List.of(_events[event] ?? const [])) {
      h(data);
    }
  }
}

/// Records every socket the service asked for.
class FakeRealtimeSocketFactory {
  final sockets = <FakeRealtimeSocket>[];

  FakeRealtimeSocket? get last => sockets.isEmpty ? null : sockets.last;

  RealtimeSocket call(RealtimeSocketConfig config) {
    final socket = FakeRealtimeSocket(config);
    sockets.add(socket);
    return socket;
  }
}

/// The `order.updated` payload from `demo-v0.md`.
Map<String, dynamic> orderUpdatedJson({
  String orderId = 'o1',
  String status = 'IN_PROGRESS',
  String reason = 'transitioned',
}) => {
  'orderId': orderId,
  'orderNumber': '1042',
  'userId': 'u1',
  'status': status,
  'paymentStatus': 'PENDING',
  'etaAt': null,
  'updatedAt': '2026-09-24T10:05:00.000Z',
  'reason': reason,
};
