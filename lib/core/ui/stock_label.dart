import 'package:flutter/material.dart';

import 'ls_theme.dart';

/// Stock as the second signal after price: icon + words, never colour alone.
/// `38 sheets in stock` (success), `Only 3 sheets left` (warning),
/// `Out of stock` (error).
class StockLabel extends StatelessWidget {
  const StockLabel({
    super.key,
    required this.qty,
    required this.unit,
    this.low = 5,
  });

  final int qty;

  /// Singular trade unit (`sheet`, `litre`, `box`); pluralised here.
  final String unit;
  final int low;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ls = lsColorsOf(theme);
    final units = pluralUnit(unit);
    final (color, icon, label) = qty <= 0
        ? (theme.colorScheme.error, Icons.block, 'Out of stock')
        : qty <= low
        ? (ls.warning, Icons.warning_amber_outlined, 'Only $qty $units left')
        : (ls.success, Icons.check_circle_outline, '$qty $units in stock');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Trade-unit plural: `sheet` → `sheets`, `box` → `boxes`; measures like
/// `kg` and `running ft` don't inflect.
String pluralUnit(String unit) {
  final u = unit.trim();
  if (u.isEmpty) return u;
  const invariant = {'kg', 'ft', 'running ft', 'sq ft', 'm', 'mm'};
  if (invariant.contains(u.toLowerCase())) return u;
  if (u.endsWith('s') || u.endsWith('x') || u.endsWith('ch')) return '${u}es';
  return '${u}s';
}
