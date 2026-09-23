import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/order.dart';
import '../../../core/models/paged.dart';
import 'owner_orders_repository.dart';

/// Segments of the owner queue and the status filter each one sends.
enum QueueSegment {
  newOrders('New', [OrderStatus.placed]),
  inProgress('In progress', [OrderStatus.inProgress]),
  outForDelivery('Out for delivery', [
    OrderStatus.outForDelivery,
    OrderStatus.deliveryFailed,
  ]),
  active('All active', []),
  done('Done', [
    OrderStatus.delivered,
    OrderStatus.cancelled,
    OrderStatus.rejected,
    OrderStatus.refunded,
  ]);

  const QueueSegment(this.label, this.statuses);

  final String label;
  final List<String> statuses;
}

const ownerQueuePollInterval = Duration(seconds: 10);

final ownerSummaryProvider = FutureProvider.autoDispose<OrdersSummary>(
  (ref) => ref.watch(ownerOrdersRepositoryProvider).summary(),
);

/// One segment of the queue, polled every [ownerQueuePollInterval]. Each
/// poll also refreshes the summary strip.
class OwnerQueueNotifier extends AsyncNotifier<Paged<AdminOrderSummary>> {
  OwnerQueueNotifier(this.segment);

  final QueueSegment segment;
  Timer? _timer;

  @override
  Future<Paged<AdminOrderSummary>> build() async {
    // onDispose also runs on every rebuild (invalidate), so reset the field
    // or the timer would never be recreated.
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    _timer ??= Timer.periodic(ownerQueuePollInterval, (_) => refresh());
    return _fetch();
  }

  Future<Paged<AdminOrderSummary>> _fetch({String? cursor}) => ref
      .read(ownerOrdersRepositoryProvider)
      .list(statuses: segment.statuses, cursor: cursor);

  Future<void> refresh() async {
    final next = await AsyncValue.guard(_fetch);
    if (next.hasValue || !state.hasValue) state = next;
    ref.invalidate(ownerSummaryProvider);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || state.isLoading) return;
    final next = await AsyncValue.guard(
      () => _fetch(cursor: current.nextCursor),
    );
    state = next.whenData(current.append);
  }
}

final ownerQueueProvider = AsyncNotifierProvider.autoDispose
    .family<OwnerQueueNotifier, Paged<AdminOrderSummary>, QueueSegment>(
      OwnerQueueNotifier.new,
    );

/// One admin order, polled every 5 s while non-terminal.
class OwnerOrderNotifier extends AsyncNotifier<AdminOrder> {
  OwnerOrderNotifier(this.orderId);

  final String orderId;
  Timer? _timer;

  @override
  Future<AdminOrder> build() async {
    ref.onDispose(_stop);
    final order = await ref.read(ownerOrdersRepositoryProvider).get(orderId);
    _sync(order);
    return order;
  }

  Future<void> refresh() async {
    final next = await AsyncValue.guard(
      () => ref.read(ownerOrdersRepositoryProvider).get(orderId),
    );
    if (next.hasValue || !state.hasValue) state = next;
    if (next.value != null) _sync(next.value!);
  }

  Future<void> transition({
    required String to,
    String? note,
    int? etaMinutes,
  }) async {
    final order = await ref
        .read(ownerOrdersRepositoryProvider)
        .transition(orderId, to: to, note: note, etaMinutes: etaMinutes);
    state = AsyncData(order);
    _sync(order);
    ref.invalidate(ownerSummaryProvider);
  }

  void _sync(AdminOrder order) {
    if (order.isTerminal) {
      _stop();
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) => refresh());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}

final ownerOrderProvider = AsyncNotifierProvider.autoDispose
    .family<OwnerOrderNotifier, AdminOrder, String>(OwnerOrderNotifier.new);
