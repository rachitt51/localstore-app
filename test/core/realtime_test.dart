import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localstore_app/core/auth/session.dart';
import 'package:localstore_app/core/auth/token_store.dart';
import 'package:localstore_app/core/models/order_updated_event.dart';
import 'package:localstore_app/core/models/user.dart';
import 'package:localstore_app/core/realtime/realtime.dart';

import '../fakes/fake_realtime_socket.dart';

const _user = User(
  id: 'u1',
  phone: '+919999999990',
  name: 'S',
  role: 'CUSTOMER',
);

AuthTokens _tokens(String access) =>
    AuthTokens(accessToken: access, refreshToken: 'r-$access', user: _user);

void main() {
  group('RealtimeService', () {
    late FakeRealtimeSocketFactory factory;
    late ProviderContainer container;

    setUp(() {
      factory = FakeRealtimeSocketFactory();
      container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          realtimeSocketFactoryProvider.overrideWithValue(factory.call),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('does nothing while signed out', () {
      final service = container.read(realtimeServiceProvider);
      expect(factory.sockets, isEmpty);
      expect(service.status.value, RealtimeStatus.off);
      expect(service.connected, isFalse);
    });

    test('connects on sign-in with the access token, URL and path', () async {
      final service = container.read(realtimeServiceProvider);
      await container.read(sessionProvider.notifier).signIn(_tokens('a1'));

      final socket = factory.last!;
      expect(factory.sockets, hasLength(1));
      expect(socket.connectCalled, isTrue);
      expect(socket.config.token, 'a1');
      expect(socket.config.path, '/ws');
      expect(socket.config.uri, '${service.baseUrl}/orders');
      expect(socket.config.uri, endsWith(':3000/orders'));
      expect(service.status.value, RealtimeStatus.connecting);

      socket.emitConnect();
      expect(service.status.value, RealtimeStatus.connected);
      expect(container.read(realtimeConnectedProvider), isTrue);

      socket.emitDisconnect();
      expect(service.status.value, RealtimeStatus.connecting);
      expect(container.read(realtimeConnectedProvider), isFalse);
    });

    test('connect() is idempotent for the same token', () async {
      final service = container.read(realtimeServiceProvider);
      await container.read(sessionProvider.notifier).signIn(_tokens('a1'));
      service.connect();
      service.connect();
      expect(factory.sockets, hasLength(1));
    });

    test('reconnects with the new token after a refresh', () async {
      final service = container.read(realtimeServiceProvider);
      await container.read(sessionProvider.notifier).signIn(_tokens('a1'));
      final first = factory.last!;
      first.emitConnect();

      await container
          .read(sessionProvider.notifier)
          .tokensRefreshed(_tokens('a2'));

      expect(first.disposed, isTrue);
      expect(factory.sockets, hasLength(2));
      expect(factory.last!.config.token, 'a2');
      expect(factory.last!.connectCalled, isTrue);
      expect(service.status.value, RealtimeStatus.connecting);
      // A late event from the replaced socket is ignored.
      first.emitConnect();
      expect(service.status.value, RealtimeStatus.connecting);
    });

    test('disconnects on sign-out', () async {
      final service = container.read(realtimeServiceProvider);
      await container.read(sessionProvider.notifier).signIn(_tokens('a1'));
      factory.last!.emitConnect();
      expect(service.connected, isTrue);

      await container.read(sessionProvider.notifier).signOut();
      expect(factory.last!.disposed, isTrue);
      expect(service.status.value, RealtimeStatus.off);
      expect(service.currentConfig, isNull);
    });

    test('parses order.updated into the events stream', () async {
      container.read(realtimeServiceProvider);
      await container.read(sessionProvider.notifier).signIn(_tokens('a1'));
      final received = <OrderUpdatedEvent>[];
      final sub = container
          .read(realtimeServiceProvider)
          .events
          .listen(received.add);

      final socket = factory.last!;
      socket.emitEvent('order.updated', orderUpdatedJson(orderId: 'o7'));
      socket.emitEvent('order.updated', 'garbage');
      socket.emitEvent('something.else', orderUpdatedJson());
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.orderId, 'o7');
      expect(received.single.status, 'IN_PROGRESS');
      await sub.cancel();
    });

    test('orderUpdatesProvider exposes the stream', () async {
      container.read(realtimeServiceProvider);
      await container.read(sessionProvider.notifier).signIn(_tokens('a1'));
      final seen = <String>[];
      final sub = container.listen(orderUpdatesProvider, (_, next) {
        if (next.hasValue) seen.add(next.value!.orderId);
      });
      factory.last!.emitEvent('order.updated', orderUpdatedJson(orderId: 'o1'));
      factory.last!.emitEvent('order.updated', orderUpdatedJson(orderId: 'o2'));
      await Future<void>.delayed(Duration.zero);
      expect(seen, ['o1', 'o2']);
      sub.close();
    });
  });

  group('OrderUpdatedEvent.fromJson', () {
    test('reads every documented field', () {
      final e = OrderUpdatedEvent.fromJson({
        ...orderUpdatedJson(orderId: 'o3', status: 'OUT_FOR_DELIVERY'),
        'etaAt': '2026-09-24T10:50:00.000Z',
        'paymentStatus': 'PAID',
        'reason': 'transitioned',
      });
      expect(e.orderId, 'o3');
      expect(e.orderNumber, '1042');
      expect(e.userId, 'u1');
      expect(e.status, 'OUT_FOR_DELIVERY');
      expect(e.paymentStatus, 'PAID');
      expect(e.etaAt?.toUtc().minute, 50);
      expect(e.updatedAt.toUtc().minute, 5);
      expect(e.reason, 'transitioned');
      expect(e.isCreated, isFalse);
    });

    test('created event without eta', () {
      final e = OrderUpdatedEvent.fromJson(
        orderUpdatedJson(status: 'PLACED', reason: 'created'),
      );
      expect(e.etaAt, isNull);
      expect(e.isCreated, isTrue);
    });
  });
}
