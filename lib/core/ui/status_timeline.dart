import 'package:flutter/material.dart';

import '../models/order.dart';
import 'format.dart';
import 'order_status.dart';

/// Vertical list of the order's `timeline[]`, rendered verbatim with the
/// status vocabulary. Newest last: done steps are `primary-container` nodes
/// on a `primary` rail, the current step a filled node in its tone with a
/// halo.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.events, this.owner = false});

  final List<OrderEvent> events;
  final bool owner;

  @override
  Widget build(BuildContext context) {
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
  });

  final OrderEvent event;
  final bool owner;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final ui = OrderStatusUi.of(event.status);
    final node = isLast
        ? Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: ui.container(theme),
              shape: BoxShape.circle,
              border: Border.all(
                color: ui.color(theme).withValues(alpha: 0.35),
                width: 3,
              ),
            ),
            child: Icon(ui.icon, size: 13, color: ui.onContainer(theme)),
          )
        : Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(ui.icon, size: 13, color: scheme.onPrimaryContainer),
          );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                node,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: scheme.primary,
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
                      color: isLast ? ui.color(theme) : null,
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
