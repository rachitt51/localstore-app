import 'package:flutter/material.dart';

import 'order_status.dart';

/// Compact status pill; label + icon so colour is never the only signal.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.owner = false});

  final String status;
  final bool owner;

  @override
  Widget build(BuildContext context) {
    final ui = OrderStatusUi.of(status);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ui.container(scheme),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ui.icon, size: 14, color: ui.onContainer(scheme)),
          const SizedBox(width: 4),
          Text(
            ui.label(owner: owner),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: ui.onContainer(scheme),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
