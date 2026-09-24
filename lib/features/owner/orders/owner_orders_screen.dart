import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/order.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/ui/format.dart';
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
    return Column(
      children: [
        summary.when(
          data: (s) => _SummaryStrip(summary: s),
          loading: () => const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Skeleton(height: 72, radius: 12),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<QueueSegment>(
              showSelectedIcon: false,
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

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

  final OrdersSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget tile(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: text.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: scheme.onPrimaryContainer,
            ),
          ),
          Text(
            label,
            style: text.labelSmall?.copyWith(color: scheme.onPrimaryContainer),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tile('New', '${summary.newCount}'),
          tile('In progress', '${summary.inProgressCount}'),
          tile('Out', '${summary.outForDeliveryCount}'),
          tile('Today', formatInr(summary.todayRevenue)),
        ],
      ),
    );
  }
}
