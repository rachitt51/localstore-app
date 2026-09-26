import 'package:flutter/material.dart';

import '../../../core/models/visit.dart';
import '../../../core/ui/ls_theme.dart';
import '../../../core/ui/order_status.dart';

/// Visit-request status as glyph + label on its tone container, matching the
/// look of [StatusChip] without touching the order-status table.
class VisitStatusChip extends StatelessWidget {
  const VisitStatusChip({super.key, required this.status});

  final String status;

  static const _table = <String, (String, StatusTone, IconData)>{
    VisitStatus.requested: (
      'Requested',
      StatusTone.neutral,
      Icons.hourglass_empty,
    ),
    VisitStatus.confirmed: (
      'Confirmed',
      StatusTone.success,
      Icons.check_circle_outline,
    ),
    VisitStatus.declined: ('Declined', StatusTone.error, Icons.block),
    VisitStatus.cancelled: (
      'Cancelled',
      StatusTone.error,
      Icons.cancel_outlined,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ls = lsColorsOf(theme);
    final (label, tone, icon) =
        _table[status] ?? (status, StatusTone.neutral, Icons.help_outline);
    final (bg, fg) = switch (tone) {
      StatusTone.neutral => (ls.neutralContainer, ls.onNeutralContainer),
      StatusTone.success => (ls.successContainer, ls.onSuccessContainer),
      StatusTone.error => (scheme.errorContainer, scheme.onErrorContainer),
      StatusTone.warning => (ls.warningContainer, ls.onWarningContainer),
      StatusTone.primary => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }
}
