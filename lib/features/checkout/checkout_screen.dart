import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/cart.dart';
import '../../core/models/order.dart';
import '../../core/models/store.dart';
import '../../core/ui/back_or_home_button.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/format.dart';
import '../../core/ui/image_placeholder.dart';
import '../../core/ui/price_text.dart';
import '../../core/ui/section.dart';
import '../../core/ui/skeleton.dart';
import '../cart/cart_notifier.dart';
import '../home/home_providers.dart';
import '../orders/orders_repository.dart';
import 'buy_now_quote.dart';
import 'checkout_draft.dart';

/// Summary lines, address, payment method, notes, "Place order".
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final _notes = TextEditingController(
    text: ref.read(checkoutDraftProvider).notes,
  );
  bool _placing = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  /// Why COD is not available for a cart checkout, or null when it is. The
  /// Buy-now path uses the quote's `codAllowed`/`codReason` instead.
  String? _codBlockedReason(StoreInfo? store, String? total) {
    if (store == null) return null;
    if (!store.codEnabled) return codReasonMessage('COD_DISABLED');
    final cap = store.codMaxAmount;
    if (cap != null && total != null && compareMoney(total, cap) > 0) {
      return codReasonMessage('ABOVE_COD_MAX', codMaxAmount: cap);
    }
    return null;
  }

  /// Why COD is not available for a Buy-now checkout. Falls back to the
  /// store-level check while the quote is loading or failed.
  String? _quoteCodBlockedReason(StoreInfo? store, AsyncValue<Quote?> quote) {
    final q = quote.value;
    if (q == null) return _codBlockedReason(store, null);
    if (q.codAllowed) return null;
    return codReasonMessage(q.codReason, codMaxAmount: store?.codMaxAmount);
  }

  Future<void> _placeOrder() async {
    final draft = ref.read(checkoutDraftProvider);
    final address = draft.address;
    if (address == null) {
      setState(() => _error = 'Choose a delivery address');
      return;
    }
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final order = await ref
          .read(ordersRepositoryProvider)
          .create(
            addressId: address.id,
            paymentMethod: draft.paymentMethod,
            notes: _notes.text.trim(),
            items: draft.pendingItems
                ?.map((i) => (variantId: i.variantId, qty: i.qty))
                .toList(),
          );
      ref.read(checkoutDraftProvider.notifier).clearAfterOrder();
      if (!draft.isBuyNow) ref.invalidate(cartProvider);
      if (!mounted) return;
      if (order.status == OrderStatus.pendingPayment) {
        context.go('/orders/${order.id}/pay');
      } else {
        context.go('/orders/${order.id}');
      }
    } catch (e) {
      setState(() {
        _placing = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(checkoutDraftProvider);
    final store = ref.watch(storeProvider).value;
    final cart = ref.watch(cartProvider);
    // Only a Buy-now draft needs a quote; a cart draft carries its totals.
    final quote = draft.isBuyNow
        ? ref.watch(buyNowQuoteProvider)
        : const AsyncValue<Quote?>.data(null);
    final scheme = Theme.of(context).colorScheme;

    final codReason = draft.isBuyNow
        ? _quoteCodBlockedReason(store, quote)
        : _codBlockedReason(store, cart.value?.total);
    final storeClosed = store != null && !store.isOpen;
    final cartEmpty = !draft.isBuyNow && (cart.value?.isEmpty ?? false);
    final quoteLoading = draft.isBuyNow && quote.isLoading;
    final blockingWarnings = draft.isBuyNow
        ? (quote.value?.hasBlockingWarnings ?? false)
        : (cart.value?.hasBlockingWarnings ?? false);

    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: const Text('Checkout'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                Section(
                  title: 'Items',
                  child: draft.isBuyNow
                      ? _BuyNowItems(items: draft.pendingItems!, quote: quote)
                      : cart.when(
                          data: (c) => _CartLines(cart: c),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text(errorMessage(e)),
                        ),
                ),
                Section(
                  title: 'Total',
                  child: draft.isBuyNow
                      ? quote.when(
                          skipLoadingOnRefresh: false,
                          data: (q) => _BillBreakdown(cart: q),
                          loading: () => const _BillSkeleton(),
                          error: (e, _) => _QuoteError(
                            error: e,
                            onRetry: () => ref.invalidate(buyNowQuoteProvider),
                          ),
                        )
                      : _BillBreakdown(cart: cart.value),
                ),
                Section(
                  title: 'Deliver to',
                  trailing: TextButton(
                    onPressed: () => context.push('/checkout/address?change=1'),
                    child: const Text('Change'),
                  ),
                  child: draft.address == null
                      ? const Text('No address selected')
                      : Text(
                          '${draft.address!.label}\n${draft.address!.oneLine}',
                        ),
                ),
                Section(
                  title: 'Payment',
                  child: Column(
                    children: [
                      RadioGroup<String>(
                        groupValue: draft.paymentMethod,
                        onChanged: (v) {
                          if (v != null) {
                            ref
                                .read(checkoutDraftProvider.notifier)
                                .setPaymentMethod(v);
                          }
                        },
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              value: PaymentMethod.cod,
                              enabled: codReason == null,
                              title: Text(
                                PaymentMethod.label(PaymentMethod.cod),
                              ),
                              subtitle: codReason == null
                                  ? null
                                  : Text(
                                      codReason,
                                      style: TextStyle(color: scheme.error),
                                    ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            for (final m in PaymentMethod.online)
                              RadioListTile<String>(
                                value: m,
                                title: Text(PaymentMethod.label(m)),
                                subtitle: const Text('Mock payment (demo)'),
                                contentPadding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Section(
                  title: 'Notes for the store',
                  child: TextField(
                    controller: _notes,
                    maxLines: 3,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (v) =>
                        ref.read(checkoutDraftProvider.notifier).setNotes(v),
                    decoration: const InputDecoration(
                      hintText: 'Delivery instructions, site contact…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InlineError(_error),
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
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed:
                      _placing ||
                          storeClosed ||
                          cartEmpty ||
                          quoteLoading ||
                          blockingWarnings ||
                          (draft.paymentMethod == PaymentMethod.cod &&
                              codReason != null)
                      ? null
                      : _placeOrder,
                  child: Text(
                    storeClosed
                        ? 'Store is closed'
                        : blockingWarnings
                        ? 'Fix the items above to continue'
                        : _placing
                        ? 'Placing order…'
                        : 'Place order',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Buy-now lines: the quoted lines (with line totals and warnings) once the
/// quote is in; the draft's lines from the product screen until then.
class _BuyNowItems extends StatelessWidget {
  const _BuyNowItems({required this.items, required this.quote});

  final List<PendingItem> items;
  final AsyncValue<Quote?> quote;

  @override
  Widget build(BuildContext context) {
    final q = quote.value;
    if (q != null) return _CartLines(cart: q);
    return Column(
      children: [
        for (final i in items)
          _SummaryLine(
            name: i.name,
            variantName: i.variantName,
            unit: i.unit,
            unitPrice: i.unitPrice,
            qty: i.qty,
            imageUrl: i.imageUrl,
          ),
      ],
    );
  }
}

/// Lines of an API-priced [Cart] (or [Quote]) with per-line warnings.
class _CartLines extends StatelessWidget {
  const _CartLines({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final l in cart.items)
          _SummaryLine(
            name: l.name,
            variantName: l.variantName,
            unit: l.unit,
            unitPrice: l.unitPrice,
            qty: l.qty,
            lineTotal: l.lineTotal,
            imageUrl: l.imageUrl,
            warning: cart.warningFor(l.variantId),
          ),
      ],
    );
  }
}

/// Subtotal / delivery / total, exactly as the API returned them.
class _BillBreakdown extends StatelessWidget {
  const _BillBreakdown({required this.cart});

  final Cart? cart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        KeyValueRow(
          label: 'Subtotal',
          value: PriceText(cart?.subtotal ?? '0.00', size: PriceSize.sm),
        ),
        KeyValueRow(
          label: 'Delivery',
          value: PriceText(cart?.deliveryFee ?? '0.00', size: PriceSize.sm),
        ),
        const Divider(),
        KeyValueRow(
          label: 'Total',
          emphasize: true,
          value: PriceText(cart?.total ?? '0.00', size: PriceSize.lg),
        ),
      ],
    );
  }
}

/// Placeholder for [_BillBreakdown] while the quote loads.
class _BillSkeleton extends StatelessWidget {
  const _BillSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row(double width) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Skeleton(width: 72, height: 14),
          const Spacer(),
          Skeleton(width: width, height: 14),
        ],
      ),
    );
    return Column(children: [row(64), row(48), const Divider(), row(88)]);
  }
}

/// The quote failed: keep the screen usable and offer a retry.
class _QuoteError extends StatelessWidget {
  const _QuoteError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InlineError("Couldn't get the total: ${errorMessage(error)}"),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.name,
    this.variantName,
    required this.unit,
    required this.unitPrice,
    required this.qty,
    this.lineTotal,
    this.imageUrl,
    this.warning,
  });

  final String name;
  final String? variantName;
  final String unit;
  final String unitPrice;
  final int qty;
  final String? lineTotal;
  final String? imageUrl;
  final CartWarning? warning;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: ProductImage(url: imageUrl, iconSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variantName == null || variantName!.isEmpty
                          ? name
                          : '$name · $variantName',
                      style: text.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$qty × ${formatInr(unitPrice)} / $unit',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (lineTotal != null) PriceText(lineTotal!, size: PriceSize.sm),
            ],
          ),
          if (warning != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 56),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: scheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      warning!.message,
                      style: text.bodySmall?.copyWith(color: scheme.error),
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
