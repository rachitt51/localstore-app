import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/order.dart';
import '../../../core/ui/back_or_home_button.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/ui/live_indicator.dart';
import '../../../core/ui/ls_theme.dart';
import '../../../core/ui/order_status.dart';
import '../../../core/ui/section.dart';
import '../../../core/ui/skeleton.dart';
import '../../orders/widgets/order_body.dart';
import '../../orders/widgets/order_status_header.dart';
import '../../orders/widgets/reason_sheet.dart';
import 'owner_orders_notifier.dart';
import 'widgets/eta_sheet.dart';

/// `/owner/orders/:id`: customer, address, items, timeline, payment and one
/// button per `allowedTransitions` entry.
class OwnerOrderScreen extends ConsumerStatefulWidget {
  const OwnerOrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OwnerOrderScreen> createState() => _OwnerOrderScreenState();
}

class _OwnerOrderScreenState extends ConsumerState<OwnerOrderScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _run(AdminOrder order, AllowedTransition t) async {
    final label = transitionLabel(from: order.status, to: t.to);
    String? note;
    int? eta;
    if (t.requiresNote) {
      note = await showReasonSheet(
        context,
        title: label.replaceAll('…', ''),
        confirmLabel: label.replaceAll('…', ''),
        hint: 'Reason (shown to the customer)',
      );
      if (note == null) return;
    }
    if (t.requiresEta && mounted) {
      eta = await showEtaSheet(context, title: label.replaceAll('…', ''));
      if (eta == null) return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(ownerOrderProvider(widget.orderId).notifier)
          .transition(to: t.to, note: note, etaMinutes: eta);
    } catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(ownerOrderProvider(widget.orderId));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(fallback: '/owner'),
        title: Text(
          order.value == null ? 'Order' : 'Order #${order.value!.orderNumber}',
        ),
        actions: const [LiveIndicator()],
      ),
      body: order.when(
        data: (o) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref
                    .read(ownerOrderProvider(widget.orderId).notifier)
                    .refresh(),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    OrderStatusHeader(order: o, owner: true),
                    Section(
                      title: 'Customer',
                      child: Text(
                        '${o.customer.displayName}\n${o.customer.phone}',
                      ),
                    ),
                    OrderBody(order: o, owner: true),
                  ],
                ),
              ),
            ),
            if (o.allowedTransitions.isNotEmpty || o.isTerminal)
              Material(
                elevation: 8,
                color: scheme.surface,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (o.allowedTransitions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No further actions',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          for (final t in _ordered(o.allowedTransitions))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TransitionButton(
                                order: o,
                                transition: t,
                                enabled: !_busy,
                                onPressed: () => _run(o, t),
                              ),
                            ),
                        InlineError(_error),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        loading: () => const SkeletonList(rows: 4, rowHeight: 100),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(ownerOrderProvider(widget.orderId)),
        ),
      ),
    );
  }

  /// The forward (primary/success-tone) transition first, then the
  /// destructive ones — TransitionActions: "the forward action is always
  /// the filled one and always first".
  List<AllowedTransition> _ordered(List<AllowedTransition> transitions) {
    bool destructive(AllowedTransition t) {
      final tone = OrderStatusUi.of(t.to).tone;
      return tone == StatusTone.error || tone == StatusTone.warning;
    }

    final sorted = [...transitions];
    sorted.sort((a, b) {
      final da = destructive(a) ? 1 : 0;
      final db = destructive(b) ? 1 : 0;
      return da.compareTo(db);
    });
    return sorted;
  }
}

/// One TransitionActions button, dense (40dp) for owner mode: the forward
/// action is filled, Reject/Cancel is a `danger` outlined button, Delivery
/// failed is a `warning` outlined button.
class _TransitionButton extends StatelessWidget {
  const _TransitionButton({
    required this.order,
    required this.transition,
    required this.enabled,
    required this.onPressed,
  });

  final AdminOrder order;
  final AllowedTransition transition;
  final bool enabled;
  final VoidCallback onPressed;

  static const _dense = Size(64, 40);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ls = lsColorsOf(theme);
    final ui = OrderStatusUi.of(transition.to);
    final label = transitionLabel(from: order.status, to: transition.to);
    final icon = Icon(ui.icon, size: 18);
    return switch (ui.tone) {
      StatusTone.error => OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: _dense,
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error),
        ),
        icon: icon,
        label: Text(label),
      ),
      StatusTone.warning => OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: _dense,
          foregroundColor: ls.warning,
          side: BorderSide(color: ls.warning),
        ),
        icon: icon,
        label: Text(label),
      ),
      _ => FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(minimumSize: _dense),
        icon: icon,
        label: Text(label),
      ),
    };
  }
}
