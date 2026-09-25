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
  });

  final ProductSummary product;
  final VoidCallback? onTap;

  /// Adds one unit of the default variant; hidden when out of stock.
  final VoidCallback? onQuickAdd;

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
                          color: inStock ? null : scheme.onSurfaceVariant,
                        ),
                      ),
                      if (inStock && onQuickAdd != null)
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
