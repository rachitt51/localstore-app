import 'package:flutter/material.dart';

import 'format.dart';

/// Renders an API money string with tabular figures.
class PriceText extends StatelessWidget {
  const PriceText(this.amount, {super.key, this.style, this.unit, this.color});

  final String amount;
  final TextStyle? style;

  /// Appended as `/unit` when given.
  final String? unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.titleMedium;
    return Text.rich(
      TextSpan(
        text: formatInr(amount),
        style: base?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
          fontWeight: FontWeight.w600,
          color: color,
        ),
        children: [
          if (unit != null && unit!.isNotEmpty)
            TextSpan(
              text: ' / $unit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
}
