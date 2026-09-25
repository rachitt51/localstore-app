import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/order.dart';
import '../../../core/ui/format.dart';
import '../../../core/ui/order_status.dart';

/// Big status banner with the ETA countdown while out for delivery.
class OrderStatusHeader extends StatelessWidget {
  const OrderStatusHeader({super.key, required this.order, this.owner = false});

  final OrderSummary order;
  final bool owner;

  @override
  Widget build(BuildContext context) {
    final ui = OrderStatusUi.of(order.status);
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final showEta =
        order.status == OrderStatus.outForDelivery && order.etaAt != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: ui.container(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ui.icon, color: ui.onContainer(theme)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ui.label(owner: owner),
                  style: text.titleLarge?.copyWith(
                    color: ui.onContainer(theme),
                  ),
                ),
              ),
            ],
          ),
          if (showEta)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: EtaCountdown(
                etaAt: order.etaAt!,
                style: text.bodyLarge?.copyWith(color: ui.onContainer(theme)),
              ),
            ),
          if (!ui.isTerminal && !showEta)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Updated ${formatTime(order.updatedAt)}',
                style: text.bodySmall?.copyWith(color: ui.onContainer(theme)),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Arriving in 42 min (by 6:15 PM)", re-rendered every 30 s.
class EtaCountdown extends StatefulWidget {
  const EtaCountdown({super.key, required this.etaAt, this.style});

  final DateTime etaAt;
  final TextStyle? style;

  @override
  State<EtaCountdown> createState() => _EtaCountdownState();
}

class _EtaCountdownState extends State<EtaCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = formatEtaRemaining(widget.etaAt);
    final label = remaining.startsWith('overdue')
        ? 'Running late: $remaining'
        : 'Arriving $remaining';
    return Text('$label (by ${formatTime(widget.etaAt)})', style: widget.style);
  }
}
