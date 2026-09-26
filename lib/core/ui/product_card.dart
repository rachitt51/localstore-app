import 'package:flutter/material.dart';

import '../models/product.dart';
import 'image_placeholder.dart';
import 'price_text.dart';
import 'stock_label.dart';

/// Storefront grid tile: image → category overline → name → price with unit
/// beside quick-add → stock. Out of stock dims the image, mutes the price
/// and drops quick-add; the card still opens the Product screen.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onQuickAdd,
    this.onQuickRemove,
    this.cartQty = 0,
  });

  final ProductSummary product;
  final VoidCallback? onTap;

  /// Adds one unit; the plus button when the cart is empty, and the plus of
  /// the stepper once the product is in the cart. Hidden when out of stock.
  final VoidCallback? onQuickAdd;

  /// Removes one unit (the stepper minus); at one unit it clears the line.
  final VoidCallback? onQuickRemove;

  /// Units of this product in the signed-in customer's cart. While it is
  /// greater than zero the quick-add button becomes a −/count/+ stepper.
  final int cartQty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final inStock = product.inStock;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ProductImage(
                url: product.imageUrl,
                name: product.name,
                category: product.category.name,
                dim: !inStock,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: PriceText(
                          product.price,
                          unit: product.unit,
                          unitBeneath: true,
                          color: inStock ? null : scheme.onSurfaceVariant,
                        ),
                      ),
                      // Empty cart: the plus button. In cart: the stepper moves
                      // to the row below (it needs the full card width).
                      if (inStock && onQuickAdd != null && cartQty == 0)
                        IconButton.filled(
                          tooltip: 'Add to cart',
                          onPressed: onQuickAdd,
                          iconSize: 18,
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Once in the cart, the −/count/+ stepper takes the stock
                  // line's place so the card keeps its height.
                  if (inStock && onQuickAdd != null && cartQty > 0)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _QtyControl(
                        qty: cartQty,
                        onAdd: onQuickAdd!,
                        onRemove: onQuickRemove,
                      ),
                    )
                  else
                    StockLabel(
                      qty: inStock ? product.stockQty : 0,
                      unit: product.unit,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact −/count/+ stepper shown on the card once the product is in the
/// cart, so the quantity can be adjusted (and cleared) without opening it.
class _QtyControl extends StatelessWidget {
  const _QtyControl({required this.qty, required this.onAdd, this.onRemove});

  final int qty;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: qty > 1 ? Icons.remove : Icons.delete_outline,
            tooltip: qty > 1 ? 'Remove one' : 'Remove from cart',
            onTap: onRemove,
            fg: scheme.onPrimaryContainer,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 20),
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: text.titleSmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            tooltip: 'Add one',
            onTap: onAdd,
            fg: scheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.fg,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: fg,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 36),
    );
  }
}
