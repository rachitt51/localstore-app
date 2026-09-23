import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/order.dart';
import '../../core/models/paged.dart';
import 'orders_repository.dart';

/// Order history, newest first, with cursor paging.
class OrdersListNotifier extends AsyncNotifier<Paged<OrderSummary>> {
  @override
  Future<Paged<OrderSummary>> build() =>
      ref.read(ordersRepositoryProvider).list();

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

/// Interval between `GET /orders/:id` polls while the order is live.
const orderPollInterval = Duration(seconds: 5);

/// One order, polled every [orderPollInterval] until its status is terminal.
class OrderDetailNotifier extends AsyncNotifier<Order> {
  OrderDetailNotifier(this.orderId);

  final String orderId;
  Timer? _timer;

  @override
  Future<Order> build() async {
    ref.onDispose(_stopPolling);
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
