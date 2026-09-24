import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Neutral box shown when a product has no image (seed data has none).
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, this.iconSize = 40});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: iconSize,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }
}

/// Product image with the placeholder for null/empty URLs and load errors.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.iconSize = 40,
  });

  final String? url;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return ImagePlaceholder(iconSize: iconSize);
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      placeholder: (_, _) => ImagePlaceholder(iconSize: iconSize),
      errorWidget: (_, _, _) => ImagePlaceholder(iconSize: iconSize),
    );
  }
}
