import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/order.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/ui/order_status.dart';
import '../../../core/ui/price_text.dart';
import '../../../core/ui/skeleton.dart';
import '../../orders/orders_screen.dart';
import 'owner_orders_notifier.dart';

/// `/owner`: summary strip + segmented queue. Refreshed on every realtime
/// `order.updated`; polled every 60 s as a fallback.
class OwnerOrdersScreen extends ConsumerStatefulWidget {
  const OwnerOrdersScreen({super.key});

  @override
  ConsumerState<OwnerOrdersScreen> createState() => _OwnerOrdersScreenState();
}

class _OwnerOrdersScreenState extends ConsumerState<OwnerOrdersScreen> {
  QueueSegment _segment = QueueSegment.newOrders;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(ownerSummaryProvider);
    final queue = ref.watch(ownerQueueProvider(_segment));
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        summary.when(
          data: (s) => _SummaryStrip(
            summary: s,
            segment: _segment,
            onSelect: (s) => setState(() => _segment = s),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Skeleton(height: 136, radius: 8),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<QueueSegment>(
              showSelectedIcon: true,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(64, 40),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                side: BorderSide(color: scheme.outline),
                selectedBackgroundColor: scheme.secondaryContainer,
                selectedForegroundColor: scheme.onSecondaryContainer,
              ),
              segments: [
                for (final s in QueueSegment.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {_segment},
              onSelectionChanged: (set) => setState(() => _segment = set.first),
            ),
          ),
        ),
        Expanded(
          child: queue.when(
            data: (page) => page.items.isEmpty
                ? EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Nothing here',
                    message: 'No orders in "${_segment.label}".',
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(ownerQueueProvider(_segment).notifier)
                        .refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: page.items.length + (page.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        if (i == page.items.length) {
                          return Center(
                            child: TextButton(
                              onPressed: () => ref
                                  .read(ownerQueueProvider(_segment).notifier)
                                  .loadMore(),
                              child: const Text('Load more'),
                            ),
                          );
                        }
                        final o = page.items[i];
                        return OrderListTile(
                          order: o,
                          owner: true,
                          subtitle:
                              '${o.customer.displayName} · ${o.customer.phone}',
                          onTap: () => context.push('/owner/orders/${o.id}'),
                        );
                      },
                    ),
                  ),
            loading: () => const SkeletonList(),
            error: (e, _) => ErrorState(
              error: e,
              onRetry: () => ref.invalidate(ownerQueueProvider(_segment)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Owner Orders-queue strip (SummaryTile): a 2×2 grid of count/revenue
/// tiles, each tappable as a status filter. The current filter gets a 2px
/// `secondary` border; counts render in Archivo (`headlineSmall`).
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.summary,
    required this.segment,
    required this.onSelect,
  });

  final OrdersSummary summary;
  final QueueSegment segment;
  final ValueChanged<QueueSegment> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'New',
                  value: '${summary.newCount}',
                  icon: Icons.receipt_outlined,
                  statusForTone: OrderStatus.placed,
                  active: segment == QueueSegment.newOrders,
                  onTap: () => onSelect(QueueSegment.newOrders),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryTile(
                  label: 'In progress',
                  value: '${summary.inProgressCount}',
                  icon: Icons.inventory_2_outlined,
                  statusForTone: OrderStatus.inProgress,
                  active: segment == QueueSegment.inProgress,
                  onTap: () => onSelect(QueueSegment.inProgress),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Out for delivery',
                  value: '${summary.outForDeliveryCount}',
                  icon: Icons.local_shipping_outlined,
                  statusForTone: OrderStatus.outForDelivery,
                  active: segment == QueueSegment.outForDelivery,
                  onTap: () => onSelect(QueueSegment.outForDelivery),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryTile(
                  label: 'Today · ${summary.todayDelivered} delivered',
                  money: summary.todayRevenue,
                  icon: Icons.payments_outlined,
                  statusForTone: OrderStatus.delivered,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.icon,
    required this.statusForTone,
    this.value,
    this.money,
    this.active = false,
    this.onTap,
  });

  final String label;
  final IconData icon;

  /// Status whose tone containers colour this tile.
  final String statusForTone;
  final String? value;
  final String? money;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final ui = OrderStatusUi.of(statusForTone);
    final onContainer = ui.onContainer(theme);
    return Material(
      color: ui.container(theme),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: active
                ? Border.all(color: scheme.secondary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: onContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (money != null)
                      PriceText(money!, size: PriceSize.lg, color: onContainer)
                    else
                      Text(
                        value ?? '',
                        style: text.headlineSmall?.copyWith(color: onContainer),
                      ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(color: onContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
