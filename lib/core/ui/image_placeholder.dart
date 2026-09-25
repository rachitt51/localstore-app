import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'ls_theme.dart';

/// The intentional no-photo state: ply cross-section bands with the
/// product's initials and category in `ply-ink`.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    this.iconSize = 40,
    this.name,
    this.category,
    this.dim = false,
  });

  /// Scales the initials; kept for small thumbnails (≤24 hides the category).
  final double iconSize;
  final String? name;
  final String? category;
  final bool dim;

  String get _initials {
    final words = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2);
    return words.map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final ls = lsColorsOf(Theme.of(context));
    final initials = _initials;
    final showCategory =
        category != null && category!.isNotEmpty && iconSize > 24;
    final child = Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            for (var i = 0; i < 6; i++)
              Expanded(child: ColoredBox(color: i.isEven ? ls.ply1 : ls.ply2)),
          ],
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (initials.isNotEmpty)
                Text(
                  initials,
                  style: TextStyle(
                    color: ls.plyInk,
                    fontSize: iconSize * 0.6,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              if (showCategory)
                Text(
                  category!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: ls.plyInk),
                ),
            ],
          ),
        ),
      ],
    );
    return dim ? Opacity(opacity: 0.45, child: child) : child;
  }
}

/// Product image with the ply placeholder for null/empty URLs and load
/// errors. [dim] greys it for out-of-stock products.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.iconSize = 40,
    this.name,
    this.category,
    this.dim = false,
  });

  final String? url;
  final BoxFit fit;
  final double iconSize;
  final String? name;
  final String? category;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => ImagePlaceholder(
      iconSize: iconSize,
      name: name,
      category: category,
      dim: dim,
    );
    if (url == null || url!.isEmpty) return placeholder();
    final image = CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      placeholder: (_, _) => placeholder(),
      errorWidget: (_, _, _) => placeholder(),
    );
    return dim ? Opacity(opacity: 0.45, child: image) : image;
  }
}
