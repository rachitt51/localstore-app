import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/order.dart';
import '../../core/ui/back_or_home_button.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/format.dart';
import '../../core/ui/skeleton.dart';
import '../orders/orders_notifier.dart';

/// Stand-in for the payment gateway: `POST /orders/:id/payment/mock-confirm`.
class MockPaymentScreen extends ConsumerStatefulWidget {
  const MockPaymentScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<MockPaymentScreen> createState() => _MockPaymentScreenState();
}

class _MockPaymentScreenState extends ConsumerState<MockPaymentScreen> {
  bool _busy = false;
  bool _failed = false;
  String? _error;

  Future<void> _confirm(String outcome) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(orderDetailProvider(widget.orderId).notifier)
          .mockConfirm(outcome: outcome);
      if (!mounted) return;
      if (outcome == 'success') {
        context.go('/orders/${widget.orderId}');
      } else {
        setState(() => _failed = true);
      }
    } catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelOrder() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(orderDetailProvider(widget.orderId).notifier)
          .cancel(reason: 'Payment abandoned');
      if (mounted) context.go('/orders/${widget.orderId}');
    } catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: BackOrHomeButton(fallback: '/orders/${widget.orderId}'),
        title: const Text('Payment'),
      ),
      body: order.when(
        data: (o) {
          if (o.status != OrderStatus.pendingPayment) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 56, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'This order no longer needs payment.',
                      style: text.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/orders/${o.id}'),
                      child: const Text('View order'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Order #${o.orderNumber}', style: text.labelLarge),
                const SizedBox(height: 4),
                Text(
                  PaymentMethod.label(o.paymentMethod),
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  formatInr(o.total),
                  style: text.displaySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Demo gateway: nothing is charged.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_failed)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Payment failed. You can try again or cancel the order.',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: _busy ? null : () => _confirm('success'),
                  child: Text(
                    _failed ? 'Retry payment' : 'Pay ${formatInr(o.total)}',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : () => _confirm('failure'),
                  child: const Text('Simulate failure'),
                ),
                if (_failed) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : _cancelOrder,
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    child: const Text('Cancel order'),
                  ),
                ],
                InlineError(_error),
              ],
            ),
          );
        },
        loading: () => const SkeletonList(rows: 2, rowHeight: 120),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }
}
