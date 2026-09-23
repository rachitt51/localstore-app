import 'package:flutter/material.dart';

import '../models/order.dart';
import 'format.dart';
import 'order_status.dart';

/// Vertical list of the order's `timeline[]`, rendered verbatim with the
/// status vocabulary. Newest last.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.events, this.owner = false});

  final List<OrderEvent> events;
  final bool owner;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (events.isEmpty) {
      return Text('No updates yet', style: text.bodyMedium);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineRow(
            event: events[i],
            owner: owner,
            isLast: i == events.length - 1,
            scheme: scheme,
            text: text,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.owner,
    required this.isLast,
    required this.scheme,
    required this.text,
  });

  final OrderEvent event;
  final bool owner;
  final bool isLast;
  final ColorScheme scheme;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final ui = OrderStatusUi.of(event.status);
    final color = isLast ? ui.color(scheme) : scheme.outline;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(ui.icon, size: 20, color: color),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ui.label(owner: owner),
                    style: text.titleSmall?.copyWith(
                      color: isLast ? ui.color(scheme) : null,
                    ),
                  ),
                  Text(
                    '${formatDateTime(event.at)} · ${_byRole(event.byRole)}',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (event.note != null && event.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(event.note!, style: text.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _byRole(String role) => switch (role) {
    'CUSTOMER' => 'you',
    'OWNER' => 'store',
    'STAFF' => 'store',
    'SYSTEM' => 'system',
    _ => role.toLowerCase(),
  };
}
