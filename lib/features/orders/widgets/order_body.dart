import 'package:flutter/material.dart';

import '../../../core/models/order.dart';
import '../../../core/ui/format.dart';
import '../../../core/ui/image_placeholder.dart';
import '../../../core/ui/ls_theme.dart';
import '../../../core/ui/price_text.dart';
import '../../../core/ui/section.dart';
import '../../../core/ui/status_timeline.dart';

/// Timeline, items, address, payment and totals; shared by the customer
/// order screen and the owner order detail.
class OrderBody extends StatelessWidget {
  const OrderBody({super.key, required this.order, this.owner = false});

  final Order order;
  final bool owner;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final ls = lsColorsOf(Theme.of(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Section(
          title: 'Updates',
          child: StatusTimeline(events: order.timeline, owner: owner),
        ),
        Section(
          title: 'Items',
          child: Column(
            children: [
              for (final line in order.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: ProductImage(url: line.imageUrl, iconSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.variantName == null ||
                                      line.variantName!.isEmpty
                                  ? line.name
                                  : '${line.name} · ${line.variantName}',
                              style: text.bodyMedium,
                            ),
                            Text(
                              '${line.qty} × ${formatInr(line.unitPrice)} / '
                              '${line.unit}',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PriceText(line.lineTotal, size: PriceSize.sm),
                    ],
                  ),
                ),
              const Divider(),
              KeyValueRow(
                label: 'Subtotal',
                value: PriceText(order.subtotal, size: PriceSize.sm),
              ),
              if (order.discount != '0.00')
                KeyValueRow(
                  label: 'Discount',
                  value: PriceText(
                    '-${order.discount}',
                    size: PriceSize.sm,
                    color: ls.success,
                  ),
                ),
              KeyValueRow(
                label: 'Delivery',
                value: PriceText(order.deliveryFee, size: PriceSize.sm),
              ),
              if (order.tax != '0.00')
                KeyValueRow(
                  label: 'Tax',
                  value: PriceText(order.tax, size: PriceSize.sm),
                ),
              KeyValueRow(
                label: 'Total',
                emphasize: true,
                value: PriceText(order.total, size: PriceSize.lg),
              ),
            ],
          ),
        ),
        if (order.address != null)
          Section(
            title: 'Delivery address',
            child: Text('${order.address!.label}\n${order.address!.oneLine}'),
          ),
        Section(
          title: 'Payment',
          child: Text(
            '${PaymentMethod.label(order.paymentMethod)} · '
            '${PaymentStatus.label(order.paymentStatus)}',
          ),
        ),
        if (order.notes != null && order.notes!.isNotEmpty)
          Section(title: 'Notes', child: Text(order.notes!)),
      ],
    );
  }
}
