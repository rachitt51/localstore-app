import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session.dart';
import '../../core/models/product.dart';
import '../../core/ui/back_or_home_button.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/format.dart';
import '../../core/ui/image_placeholder.dart';
import '../../core/ui/price_text.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/stock_label.dart';
import '../account/account_menu.dart';
import '../cart/cart_notifier.dart';
import '../cart/widgets/cart_action.dart';
import '../checkout/checkout_draft.dart';
import '../home/home_providers.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  String? _variantId;
  int _qty = 1;
  String? _error;
  bool _busy = false;

  Variant? _selected(Product product) {
    final variants = product.activeVariants;
    if (variants.isEmpty) return null;
    return variants.firstWhere(
      (v) => v.id == _variantId,
      orElse: () =>
          variants.firstWhere((v) => v.inStock, orElse: () => variants.first),
    );
  }

  /// Guests are sent to login and come back here.
  bool _requireSignIn() {
    if (ref.read(sessionProvider).isSignedIn) return true;
    final from = Uri.encodeComponent('/products/${widget.productId}');
    context.push('/login?from=$from');
    return false;
  }

  Future<void> _addToCart(Variant variant) async {
    if (!_requireSignIn()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(cartProvider.notifier).add(variant.id, _qty);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            // Short: the timer restarts on route transitions, so a long one
            // follows the user through the checkout funnel.
            duration: const Duration(seconds: 2),
            content: Text('Added $_qty to cart'),
            action: SnackBarAction(
              label: 'View cart',
              onPressed: () => context.push('/cart'),
            ),
          ),
        );
    } catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _buyNow(Product product, Variant variant) {
    ref.read(checkoutDraftProvider.notifier).startBuyNow([
      PendingItem(
        variantId: variant.id,
        qty: _qty,
        name: product.name,
        variantName: product.activeVariants.length > 1 ? variant.name : null,
        unit: product.unit,
        unitPrice: variant.price,
        imageUrl: product.imageUrl,
      ),
    ]);
    if (ref.read(sessionProvider).isSignedIn) {
      context.push('/checkout/address');
    } else {
      // The draft survives the login; the router lands on the address step.
      context.push('/login?from=${Uri.encodeComponent('/checkout/address')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productProvider(widget.productId));
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: Text(product.value?.name ?? 'Product'),
        actions: const [CartAction(), AccountMenuButton()],
      ),
      body: product.when(
        data: _body,
        loading: () => const SkeletonList(rows: 4, rowHeight: 120),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(productProvider(widget.productId)),
        ),
      ),
    );
  }

  Widget _body(Product product) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final variants = product.activeVariants;
    final variant = _selected(product);
    final stock = variant?.stockQty ?? 0;
    final inStock = stock > 0;
    if (_qty > stock && stock > 0) _qty = stock;
    final price = variant?.price ?? product.price;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _ImageCarousel(images: product.images),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category.name.toUpperCase(),
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(product.name, style: text.headlineSmall),
                    const SizedBox(height: 8),
                    PriceText(price, size: PriceSize.xl, unit: product.unit),
                    const SizedBox(height: 6),
                    StockLabel(qty: inStock ? stock : 0, unit: product.unit),
                    if (product.autoApprove)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Auto-confirmed on order',
                          style: text.bodySmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    if (variants.length > 1) ...[
                      const SizedBox(height: 16),
                      Text('Variant', style: text.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final v in variants)
                            _VariantChip(
                              label: v.name,
                              sub: v.inStock
                                  ? '${formatInr(v.price)} / ${product.unit}'
                                  : 'Out of stock',
                              selected: v.id == variant?.id,
                              disabled: !v.inStock,
                              onTap: () => setState(() {
                                _variantId = v.id;
                                _qty = 1;
                                _error = null;
                              }),
                            ),
                        ],
                      ),
                    ],
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Description', style: text.titleSmall),
                      const SizedBox(height: 4),
                      Text(product.description!, style: text.bodyMedium),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Material(
          elevation: 8,
          color: scheme.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('Quantity', style: text.titleSmall),
                      const Spacer(),
                      QtyStepper(
                        value: _qty,
                        max: inStock ? stock : 1,
                        enabled: inStock && !_busy,
                        onChanged: (v) => setState(() => _qty = v),
                      ),
                    ],
                  ),
                  InlineError(_error),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: inStock && !_busy && variant != null
                              ? () => _buyNow(product, variant)
                              : null,
                          child: const Text('Buy now'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: inStock && !_busy && variant != null
                              ? () => _addToCart(variant)
                              : null,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add to cart'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.images});

  final List<String> images;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const AspectRatio(
        aspectRatio: 4 / 3,
        child: ImagePlaceholder(iconSize: 72),
      );
    }
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => ProductImage(url: widget.images[i]),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.images.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface
                                  .withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Variant picker chip: size/finish with its own price and stock.
/// Selected: 2px `primary` border + `primary-container` + check. Out of
/// stock: struck label, muted border, still visible so buyers know the size
/// exists (still tappable, so its price and stock can be checked).
class _VariantChip extends StatelessWidget {
  const _VariantChip({
    required this.label,
    required this.sub,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final String sub;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? scheme.primary
                : disabled
                ? scheme.outlineVariant
                : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 16, color: scheme.onPrimaryContainer),
              const SizedBox(width: 4),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.labelMedium?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : disabled
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                    decoration: disabled ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  sub,
                  style: text.bodySmall?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
