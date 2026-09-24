import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:localstore_app/core/api/auth_interceptor.dart';
import 'package:localstore_app/core/models/cart.dart';
import 'package:localstore_app/core/models/order.dart';
import 'package:localstore_app/core/models/paged.dart';
import 'package:localstore_app/core/realtime/realtime.dart';
import 'package:localstore_app/features/orders/order_screen.dart';
import 'package:localstore_app/features/orders/orders_notifier.dart';
import 'package:localstore_app/features/orders/orders_repository.dart';
import 'package:localstore_app/features/orders/widgets/order_status_header.dart';

import '../fakes/fake_realtime_socket.dart';
import '../fixtures.dart';

/// In-memory stand-in for `/orders`; counts fetches to verify polling.
class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository(this.order);

  Order order;
  int fetches = 0;
  String? cancelledWith;

  @override
  Future<Order> get(String id) async {
    fetches++;
    return order;
  }

  @override
  Future<Order> cancel(String id, {String? reason}) async {
    cancelledWith = reason ?? '';
    order = Order.fromJson(orderJson(status: 'CANCELLED', canCancel: false));
    return order;
  }

  @override
  Future<Order> create({
    required String addressId,
    required String paymentMethod,
    String? notes,
    List<OrderItemInput>? items,
  }) => throw UnimplementedError();

  @override
  Future<Paged<OrderSummary>> list({String? cursor, int? limit}) =>
      throw UnimplementedError();

  @override
  Future<Order> mockConfirm(String id, {required String outcome}) =>
      throw UnimplementedError();

  @override
  Future<Quote> quote(List<OrderItemInput> items, {String? addressId}) =>
      throw UnimplementedError();
}

/// A [RealtimeService] on a fake socket, already "signed in" so tests can
/// push `order.updated` through [socket] without a session or network.
class FakeRealtime {
  FakeRealtime() {
    service = RealtimeService(
      tokens: TokenCache()..accessToken = 'a1',
      socketFactory: factory.call,
    )..connect();
    socket = factory.last!;
  }

  final factory = FakeRealtimeSocketFactory();
  late final RealtimeService service;
  late final FakeRealtimeSocket socket;
}

Widget _app(FakeOrdersRepository repo, {FakeRealtime? realtime}) =>
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        ordersRepositoryProvider.overrideWithValue(repo),
        if (realtime != null)
          realtimeServiceProvider.overrideWithValue(realtime.service),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const OrderScreen(orderId: 'o1'),
            ),
          ],
        ),
      ),
    );

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  testWidgets('out for delivery: ETA countdown shown, no cancel button', (
    tester,
  ) async {
    final eta = DateTime.now().add(const Duration(minutes: 45));
    final repo = FakeOrdersRepository(
      Order.fromJson(
        orderJson(
          status: OrderStatus.outForDelivery,
          canCancel: false,
          etaAt: eta.toUtc().toIso8601String(),
          etaMinutes: 45,
        ),
      ),
    );
    await tester.pumpWidget(_app(repo));
    await tester.pump();

    expect(find.text('Order #1042'), findsOneWidget);
    expect(find.text('On the way'), findsWidgets);
    expect(find.byType(EtaCountdown), findsOneWidget);
    expect(find.textContaining('Arriving in 4'), findsOneWidget);
    expect(find.text('BWP Plywood 18 mm · 8×4'), findsOneWidget);
    expect(find.text('ETA 45 min'), findsOneWidget);
    // Scroll to the end: the whole body is built and there is no cancel.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pump();
    expect(find.text('Cancel order'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);

    // Non-terminal → fallback poll every 30 s.
    expect(repo.fetches, 1);
    await tester.pump(orderPollInterval);
    await tester.pump();
    expect(repo.fetches, 2);

    await _unmount(tester);
  });

  testWidgets('realtime order.updated for this order triggers a re-fetch', (
    tester,
  ) async {
    final repo = FakeOrdersRepository(
      Order.fromJson(orderJson(status: OrderStatus.placed, canCancel: true)),
    );
    final realtime = FakeRealtime();
    await tester.pumpWidget(_app(repo, realtime: realtime));
    await tester.pump();
    expect(find.text('Order placed'), findsWidgets);
    expect(repo.fetches, 1);

    // Socket up → "Live" in the app bar.
    expect(find.text('Live'), findsNothing);
    realtime.socket.emitConnect();
    await tester.pump();
    expect(find.text('Live'), findsOneWidget);

    // An event for another order is ignored.
    realtime.socket.emitEvent('order.updated', orderUpdatedJson(orderId: 'x'));
    await tester.pump();
    expect(repo.fetches, 1);

    // The owner accepted: the API now says IN_PROGRESS; the event makes the
    // screen re-fetch well before the 30 s poll.
    repo.order = Order.fromJson(
      orderJson(status: OrderStatus.inProgress, canCancel: true),
    );
    realtime.socket.emitEvent(
      'order.updated',
      orderUpdatedJson(orderId: 'o1', status: OrderStatus.inProgress),
    );
    await tester.pump();
    await tester.pump();
    expect(repo.fetches, 2);
    expect(find.text('Being prepared'), findsWidgets);

    // Socket drops → the indicator says so.
    realtime.socket.emitDisconnect();
    await tester.pump();
    expect(find.text('Reconnecting'), findsOneWidget);

    await _unmount(tester);
    realtime.service.dispose();
  });

  testWidgets('placed order: cancel button visible and cancels with reason', (
    tester,
  ) async {
    final repo = FakeOrdersRepository(
      Order.fromJson(orderJson(status: OrderStatus.placed, canCancel: true)),
    );
    await tester.pumpWidget(_app(repo));
    await tester.pump();

    expect(find.text('Order placed'), findsWidgets);
    expect(find.byType(EtaCountdown), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Cancel order'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cancel order'), findsOneWidget);

    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this order?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ordered by mistake');
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel order'));
    await tester.pumpAndSettle();

    expect(repo.cancelledWith, 'Ordered by mistake');
    expect(find.text('Cancelled'), findsWidgets);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pump();
    expect(find.text('Cancel order'), findsNothing);

    await _unmount(tester);
  });

  testWidgets('delivered order does not poll', (tester) async {
    final repo = FakeOrdersRepository(
      Order.fromJson(
        orderJson(status: OrderStatus.delivered, canCancel: false),
      ),
    );
    await tester.pumpWidget(_app(repo));
    await tester.pump();
    expect(find.text('Delivered'), findsWidgets);
    await tester.pump(orderPollInterval * 2);
    expect(repo.fetches, 1);
    await _unmount(tester);
  });
}
