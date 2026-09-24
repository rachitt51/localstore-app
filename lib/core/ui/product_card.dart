import 'package:flutter/material.dart';

import '../models/product.dart';
import 'image_placeholder.dart';
import 'price_text.dart';

/// Grid tile: image (or placeholder), name, price per unit, stock badge.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final ProductSummary product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: product.imageUrl),
                  if (!product.inStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Out of stock',
                          style: text.labelSmall?.copyWith(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  PriceText(product.price, unit: product.unit),
                  if (product.inStock)
                    Text(
                      '${product.stockQty} in stock',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
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
