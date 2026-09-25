import 'package:flutter/material.dart';

import 'order_status.dart';

/// Order status as glyph + label on its tone container (`radius-xs`), so
/// colour is never the only signal. Not a Material Chip: it isn't tappable.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.owner = false});

  final String status;
  final bool owner;

  @override
  Widget build(BuildContext context) {
    final ui = OrderStatusUi.of(status);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ui.container(theme),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ui.icon, size: 14, color: ui.onContainer(theme)),
          const SizedBox(width: 4),
          Text(
            ui.label(owner: owner),
            style: theme.textTheme.labelMedium?.copyWith(
              color: ui.onContainer(theme),
            ),
          ),
        ],
      ),
    );
  }
}
