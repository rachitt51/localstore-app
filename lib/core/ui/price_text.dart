import 'package:flutter/material.dart';

import 'format.dart';
import 'ls_theme.dart';

/// PriceText sizes from the design system: xl Product screen, lg totals,
/// md cards and line totals, sm unit prices and bill rows.
enum PriceSize { xl, lg, md, sm }

/// Renders an API money string with tabular figures; the unit (if any) is a
/// muted `/ unit` suffix in the `price-unit` style.
class PriceText extends StatelessWidget {
  const PriceText(
    this.amount, {
    super.key,
    this.size = PriceSize.md,
    this.style,
    this.unit,
    this.color,
  });

  final String amount;

  /// Overrides [size] when given (tabular figures are still applied).
  final TextStyle? style;
  final PriceSize size;

  /// Appended as `/unit` when given.
  final String? unit;
  final Color? color;

  static TextStyle styleFor(PriceSize size) => switch (size) {
    PriceSize.xl => lsPrice(28, 34, FontWeight.w700),
    PriceSize.lg => lsPrice(20, 26, FontWeight.w700),
    PriceSize.md => lsPrice(16, 22, FontWeight.w700),
    PriceSize.sm => lsPrice(14, 20, FontWeight.w600),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = style != null
        ? style!.copyWith(fontFeatures: const [FontFeature.tabularFigures()])
        : styleFor(size).copyWith(color: scheme.onSurface);
    return Text.rich(
      TextSpan(
        text: formatInr(amount),
        style: color != null ? base.copyWith(color: color) : base,
        children: [
          if (unit != null && unit!.isNotEmpty)
            TextSpan(
              text: ' / $unit',
              style: lsPrice(
                12,
                16,
                FontWeight.w500,
              ).copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
