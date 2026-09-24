import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/order.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/format.dart';
import '../../core/ui/price_text.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/status_chip.dart';
import 'orders_notifier.dart';

/// Order history tab.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: orders.when(
        data: (page) => page.items.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'Your orders will show up here.',
                action: FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Browse products'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(ordersListProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: page.items.length + (page.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    if (i == page.items.length) {
                      return Center(
                        child: TextButton(
                          onPressed: () =>
                              ref.read(ordersListProvider.notifier).loadMore(),
                          child: const Text('Load more'),
                        ),
                      );
                    }
                    return OrderListTile(
                      order: page.items[i],
                      onTap: () => context.push('/orders/${page.items[i].id}'),
                    );
                  },
                ),
              ),
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(ordersListProvider),
        ),
      ),
    );
  }
}

/// Shared by the customer list and the owner queue.
class OrderListTile extends StatelessWidget {
  const OrderListTile({
    super.key,
    required this.order,
    required this.onTap,
    this.owner = false,
    this.subtitle,
  });

  final OrderSummary order;
  final VoidCallback onTap;
  final bool owner;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      title: Row(
        children: [
          Expanded(
            child: Text('Order #${order.orderNumber}', style: text.titleSmall),
          ),
          StatusChip(status: order.status, owner: owner),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) Text(subtitle!, style: text.bodyMedium),
            Text(
              '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · '
              '${PaymentMethod.label(order.paymentMethod)} · '
              '${formatDateTime(order.createdAt)}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      trailing: PriceText(order.total, style: text.titleSmall),
    );
  }
}
