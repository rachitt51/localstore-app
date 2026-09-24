import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/order.dart';
import '../../core/models/paged.dart';
import '../../core/realtime/realtime.dart';
import 'orders_repository.dart';

/// Order history, newest first, with cursor paging. Refreshes on every
/// realtime `order.updated` (a new order or a status change of any own order).
class OrdersListNotifier extends AsyncNotifier<Paged<OrderSummary>> {
  @override
  Future<Paged<OrderSummary>> build() {
    ref.listen(orderUpdatesProvider, (_, next) {
      if (next.hasValue) refresh();
    });
    return ref.read(ordersRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(ref.read(ordersRepositoryProvider).list);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || state.isLoading) return;
    final next = await AsyncValue.guard(
      () => ref.read(ordersRepositoryProvider).list(cursor: current.nextCursor),
    );
    state = next.whenData(current.append);
  }
}

final ordersListProvider =
    AsyncNotifierProvider.autoDispose<OrdersListNotifier, Paged<OrderSummary>>(
      OrdersListNotifier.new,
    );

/// Fallback interval between `GET /orders/:id` polls while the order is live.
/// Realtime events trigger an immediate re-fetch; this only covers a socket
/// that is down (`demo-v0.md`, Realtime: customer order 30 s).
const orderPollInterval = Duration(seconds: 30);

/// One order: re-fetched on its `order.updated` events, polled every
/// [orderPollInterval] as a fallback until its status is terminal.
class OrderDetailNotifier extends AsyncNotifier<Order> {
  OrderDetailNotifier(this.orderId);

  final String orderId;
  Timer? _timer;

  @override
  Future<Order> build() async {
    ref.onDispose(_stopPolling);
    ref.listen(orderUpdatesProvider, (_, next) {
      if (next.value?.orderId == orderId) refresh();
    });
    final order = await ref.read(ordersRepositoryProvider).get(orderId);
    _syncPolling(order);
    return order;
  }

  Future<void> refresh() async {
    final next = await AsyncValue.guard(
      () => ref.read(ordersRepositoryProvider).get(orderId),
    );
    // Keep the last good order visible on a transient poll failure.
    if (next.hasValue || !state.hasValue) state = next;
    if (next.value != null) _syncPolling(next.value!);
  }

  Future<void> cancel({String? reason}) async {
    final order = await ref
        .read(ordersRepositoryProvider)
        .cancel(orderId, reason: reason);
    state = AsyncData(order);
    _syncPolling(order);
  }

  Future<void> mockConfirm({required String outcome}) async {
    final order = await ref
        .read(ordersRepositoryProvider)
        .mockConfirm(orderId, outcome: outcome);
    state = AsyncData(order);
    _syncPolling(order);
  }

  void _syncPolling(Order order) {
    if (order.isTerminal) {
      _stopPolling();
      return;
    }
    _timer ??= Timer.periodic(orderPollInterval, (_) => refresh());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }
}

final orderDetailProvider = AsyncNotifierProvider.autoDispose
    .family<OrderDetailNotifier, Order, String>(OrderDetailNotifier.new);
