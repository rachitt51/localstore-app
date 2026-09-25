import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/cart.dart';
import '../../core/ui/back_or_home_button.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/image_placeholder.dart';
import '../../core/ui/ls_theme.dart';
import '../../core/ui/price_text.dart';
import '../../core/ui/qty_stepper.dart';
import '../../core/ui/section.dart';
import '../../core/ui/skeleton.dart';
import '../checkout/checkout_draft.dart';
import '../home/home_providers.dart';
import 'cart_notifier.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  String? _error;
  String? _busyVariant;

  Future<void> _setQty(String variantId, int qty) async {
    setState(() {
      _busyVariant = variantId;
      _error = null;
    });
    try {
      await ref.read(cartProvider.notifier).setQty(variantId, qty);
    } catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busyVariant = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final store = ref.watch(storeProvider).value;
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: const Text('Cart'),
      ),
      body: cart.when(
        data: (c) => c.isEmpty
            ? EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Your cart is empty',
                message: 'Browse the store and add what you need.',
                action: FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Browse products'),
                ),
              )
            : _body(c, storeOpen: store?.isOpen ?? true),
        loading: () => const SkeletonList(rows: 3, rowHeight: 88),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.read(cartProvider.notifier).refresh(),
        ),
      ),
    );
  }

  Widget _body(Cart cart, {required bool storeOpen}) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ls = lsColorsOf(Theme.of(context));
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(cartProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                if (!storeOpen)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ls.neutralContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'The store is closed right now. Your cart is kept; '
                      'check out when it opens.',
                      style: text.bodyMedium?.copyWith(
                        color: ls.onNeutralContainer,
                      ),
                    ),
                  ),
                for (final line in cart.items)
                  _CartLineTile(
                    line: line,
                    warning: cart.warningFor(line.variantId),
                    busy: _busyVariant == line.variantId,
                    onQty: (q) => _setQty(line.variantId, q),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InlineError(_error),
                  ),
                Section(
                  title: 'Bill',
                  child: Column(
                    children: [
                      KeyValueRow(
                        label: 'Subtotal',
                        value: PriceText(cart.subtotal, size: PriceSize.sm),
                      ),
                      KeyValueRow(
                        label: 'Delivery',
                        value: PriceText(cart.deliveryFee, size: PriceSize.sm),
                      ),
                      const Divider(),
                      KeyValueRow(
                        label: 'Total',
                        emphasize: true,
                        value: PriceText(cart.total, size: PriceSize.lg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Material(
          elevation: 8,
          color: scheme.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: storeOpen && !cart.hasBlockingWarnings
                    ? () {
                        ref
                            .read(checkoutDraftProvider.notifier)
                            .startFromCart();
                        context.push('/checkout/address');
                      }
                    : null,
                child: Text(
                  cart.hasBlockingWarnings
                      ? 'Fix the items above to continue'
                      : 'Checkout',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    required this.warning,
    required this.busy,
    required this.onQty,
  });

  final CartLine line;
  final CartWarning? warning;
  final bool busy;
  final ValueChanged<int> onQty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: ProductImage(url: line.imageUrl, iconSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      style: text.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (line.variantName != null &&
                        line.variantName!.isNotEmpty)
                      Text(line.variantName!, style: text.bodySmall),
                    PriceText(
                      line.unitPrice,
                      size: PriceSize.sm,
                      unit: line.unit,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        QtyStepper(
                          value: line.qty,
                          min: 0,
                          max: line.stockQty > 0 ? line.stockQty : line.qty,
                          enabled: !busy,
                          compact: true,
                          onChanged: onQty,
                        ),
                        const Spacer(),
                        PriceText(line.lineTotal),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (warning != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: scheme.error),
                  const SizedBox(width: 6),
                  Text(
                    warning!.message,
                    style: text.bodySmall?.copyWith(color: scheme.error),
                  ),
                  const Spacer(),
                  if (warning!.code == 'OUT_OF_STOCK')
                    TextButton(
                      onPressed: busy ? null : () => onQty(0),
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}
