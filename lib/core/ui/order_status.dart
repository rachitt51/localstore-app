import 'package:flutter/material.dart';

import '../models/order.dart';
import 'ls_theme.dart';

enum StatusTone { neutral, primary, warning, success, error }

/// The single source of order-status wording, colour and icon for both
/// shells (app-ux.md §6, updated for the demo statuses).
class OrderStatusUi {
  const OrderStatusUi._({
    required this.status,
    required this.customerLabel,
    required this.ownerLabel,
    required this.tone,
    required this.icon,
  });

  final String status;
  final String customerLabel;
  final String ownerLabel;
  final StatusTone tone;
  final IconData icon;

  static const _table = <String, OrderStatusUi>{
    OrderStatus.pendingPayment: OrderStatusUi._(
      status: OrderStatus.pendingPayment,
      customerLabel: 'Awaiting payment',
      ownerLabel: 'Awaiting payment',
      tone: StatusTone.neutral,
      icon: Icons.hourglass_empty,
    ),
    OrderStatus.placed: OrderStatusUi._(
      status: OrderStatus.placed,
      customerLabel: 'Order placed',
      ownerLabel: 'New',
      tone: StatusTone.primary,
      icon: Icons.receipt_outlined,
    ),
    OrderStatus.inProgress: OrderStatusUi._(
      status: OrderStatus.inProgress,
      customerLabel: 'Being prepared',
      ownerLabel: 'In progress',
      tone: StatusTone.primary,
      icon: Icons.inventory_2_outlined,
    ),
    OrderStatus.outForDelivery: OrderStatusUi._(
      status: OrderStatus.outForDelivery,
      customerLabel: 'On the way',
      ownerLabel: 'Out for delivery',
      tone: StatusTone.primary,
      icon: Icons.local_shipping_outlined,
    ),
    OrderStatus.delivered: OrderStatusUi._(
      status: OrderStatus.delivered,
      customerLabel: 'Delivered',
      ownerLabel: 'Delivered',
      tone: StatusTone.success,
      icon: Icons.check_circle_outline,
    ),
    OrderStatus.deliveryFailed: OrderStatusUi._(
      status: OrderStatus.deliveryFailed,
      customerLabel: 'Delivery attempt failed',
      ownerLabel: 'Delivery failed',
      tone: StatusTone.warning,
      icon: Icons.warning_amber_outlined,
    ),
    OrderStatus.rejected: OrderStatusUi._(
      status: OrderStatus.rejected,
      customerLabel: "Couldn't be accepted",
      ownerLabel: 'Rejected',
      tone: StatusTone.error,
      icon: Icons.block,
    ),
    OrderStatus.cancelled: OrderStatusUi._(
      status: OrderStatus.cancelled,
      customerLabel: 'Cancelled',
      ownerLabel: 'Cancelled',
      tone: StatusTone.error,
      icon: Icons.cancel_outlined,
    ),
    OrderStatus.refunded: OrderStatusUi._(
      status: OrderStatus.refunded,
      customerLabel: 'Refunded',
      ownerLabel: 'Refunded',
      tone: StatusTone.neutral,
      icon: Icons.undo,
    ),
  };

  /// Never throws: an unknown status renders its raw name in a neutral tone.
  static OrderStatusUi of(String status) =>
      _table[status] ??
      OrderStatusUi._(
        status: status,
        customerLabel: _humanize(status),
        ownerLabel: _humanize(status),
        tone: StatusTone.neutral,
        icon: Icons.help_outline,
      );

  static bool isKnown(String status) => _table.containsKey(status);

  String label({required bool owner}) => owner ? ownerLabel : customerLabel;

  bool get isTerminal => OrderStatus.isTerminal(status);

  /// Foreground colour for the tone.
  Color color(ThemeData theme) {
    final scheme = theme.colorScheme;
    final ls = lsColorsOf(theme);
    return switch (tone) {
      StatusTone.neutral => scheme.onSurfaceVariant,
      StatusTone.primary => scheme.primary,
      StatusTone.warning => ls.warning,
      StatusTone.success => ls.success,
      StatusTone.error => scheme.error,
    };
  }

  /// Container colour for chips and headers.
  Color container(ThemeData theme) {
    final scheme = theme.colorScheme;
    final ls = lsColorsOf(theme);
    return switch (tone) {
      StatusTone.neutral => ls.neutralContainer,
      StatusTone.primary => scheme.primaryContainer,
      StatusTone.warning => ls.warningContainer,
      StatusTone.success => ls.successContainer,
      StatusTone.error => scheme.errorContainer,
    };
  }

  Color onContainer(ThemeData theme) {
    final scheme = theme.colorScheme;
    final ls = lsColorsOf(theme);
    return switch (tone) {
      StatusTone.neutral => ls.onNeutralContainer,
      StatusTone.primary => scheme.onPrimaryContainer,
      StatusTone.warning => ls.onWarningContainer,
      StatusTone.success => ls.onSuccessContainer,
      StatusTone.error => scheme.onErrorContainer,
    };
  }

  static String _humanize(String raw) {
    if (raw.isEmpty) return 'Unknown';
    final words = raw.toLowerCase().split('_');
    return words.first[0].toUpperCase() +
        words.first.substring(1) +
        (words.length > 1 ? ' ${words.skip(1).join(' ')}' : '');
  }
}

/// Button labels for owner transitions, keyed on `(from, to)`.
String transitionLabel({required String from, required String to}) {
  switch (to) {
    case OrderStatus.inProgress:
      return from == OrderStatus.placed ? 'Accept' : 'Start progress';
    case OrderStatus.rejected:
      return 'Reject…';
    case OrderStatus.outForDelivery:
      return from == OrderStatus.deliveryFailed
          ? 'Re-dispatch…'
          : 'Out for delivery…';
    case OrderStatus.delivered:
      return 'Delivered';
    case OrderStatus.deliveryFailed:
      return 'Delivery failed…';
    case OrderStatus.cancelled:
      return 'Cancel order…';
    default:
      return OrderStatusUi.of(to).ownerLabel;
  }
}
