import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/order.dart';
import '../../core/ui/back_or_home_button.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/skeleton.dart';
import 'orders_notifier.dart';
import 'widgets/order_body.dart';
import 'widgets/order_status_header.dart';
import 'widgets/reason_sheet.dart';

/// Live customer order: status header, ETA countdown, timeline, items,
/// cancel. Polls every 5 s while the status is not terminal.
class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  bool _cancelling = false;
  String? _error;

  Future<void> _cancel() async {
    final result = await showReasonSheet(
      context,
      title: 'Cancel this order?',
      hint: 'Reason (optional)',
      confirmLabel: 'Cancel order',
      required: false,
    );
    if (result == null || !mounted) return;
    setState(() {
      _cancelling = true;
      _error = null;
    });
    try {
      await ref
          .read(orderDetailProvider(widget.orderId).notifier)
          .cancel(reason: result.isEmpty ? null : result);
    } catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(fallback: '/orders'),
        title: Text(
          order.value == null ? 'Order' : 'Order #${order.value!.orderNumber}',
        ),
      ),
      body: order.when(
        data: (o) => RefreshIndicator(
          onRefresh: () =>
              ref.read(orderDetailProvider(widget.orderId).notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              OrderStatusHeader(order: o),
              if (o.status == OrderStatus.pendingPayment)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: FilledButton.icon(
                    onPressed: () => context.push('/orders/${o.id}/pay'),
                    icon: const Icon(Icons.payment),
                    label: const Text('Complete payment'),
                  ),
                ),
              OrderBody(order: o),
              if (o.canCancel)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _cancelling ? null : _cancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(
                          _cancelling ? 'Cancelling…' : 'Cancel order',
                        ),
                      ),
                      InlineError(_error),
                    ],
                  ),
                ),
            ],
          ),
        ),
        loading: () => const SkeletonList(rows: 4, rowHeight: 100),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }
}
