import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/order.dart';
import '../../core/models/store.dart';
import '../../core/ui/back_or_home_button.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/format.dart';
import '../../core/ui/image_placeholder.dart';
import '../../core/ui/price_text.dart';
import '../../core/ui/section.dart';
import '../cart/cart_notifier.dart';
import '../home/home_providers.dart';
import '../orders/orders_repository.dart';
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

  /// Why COD is not available, or null when it is.
  String? _codBlockedReason(StoreInfo? store, String? total) {
    if (store == null) return null;
    if (!store.codEnabled) return 'Cash on delivery is not available';
    final cap = store.codMaxAmount;
    if (cap != null && total != null && compareMoney(total, cap) > 0) {
      return 'Cash on delivery is available up to ${formatInr(cap)}';
    }
    return null;
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final total = draft.isBuyNow ? null : cart.value?.total;
    final codReason = _codBlockedReason(store, total);
    final storeClosed = store != null && !store.isOpen;
    final cartEmpty = !draft.isBuyNow && (cart.value?.isEmpty ?? false);

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
                      ? Column(
                          children: [
                            for (final i in draft.pendingItems!)
                              _SummaryLine(
                                name: i.name,
                                variantName: i.variantName,
                                unit: i.unit,
                                unitPrice: i.unitPrice,
                                qty: i.qty,
                                imageUrl: i.imageUrl,
                              ),
                          ],
                        )
                      : cart.when(
                          data: (c) => Column(
                            children: [
                              for (final l in c.items)
                                _SummaryLine(
                                  name: l.name,
                                  variantName: l.variantName,
                                  unit: l.unit,
                                  unitPrice: l.unitPrice,
                                  qty: l.qty,
                                  lineTotal: l.lineTotal,
                                  imageUrl: l.imageUrl,
                                ),
                            ],
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text(errorMessage(e)),
                        ),
                ),
                Section(
                  title: 'Total',
                  child: draft.isBuyNow
                      ? Text(
                          'The total is calculated by the store when you '
                          'place the order and shown on the order screen.',
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : Column(
                          children: [
                            KeyValueRow(
                              label: 'Subtotal',
                              value: PriceText(
                                cart.value?.subtotal ?? '0.00',
                                style: text.bodyMedium,
                              ),
                            ),
                            KeyValueRow(
                              label: 'Delivery',
                              value: PriceText(
                                cart.value?.deliveryFee ?? '0.00',
                                style: text.bodyMedium,
                              ),
                            ),
                            const Divider(),
                            KeyValueRow(
                              label: 'Total',
                              emphasize: true,
                              value: PriceText(cart.value?.total ?? '0.00'),
                            ),
                          ],
                        ),
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
                          (draft.paymentMethod == PaymentMethod.cod &&
                              codReason != null)
                      ? null
                      : _placeOrder,
                  child: Text(
                    storeClosed
                        ? 'Store is closed'
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

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.name,
    this.variantName,
    required this.unit,
    required this.unitPrice,
    required this.qty,
    this.lineTotal,
    this.imageUrl,
  });

  final String name;
  final String? variantName;
  final String unit;
  final String unitPrice;
  final int qty;
  final String? lineTotal;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
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
          if (lineTotal != null) PriceText(lineTotal!, style: text.bodyMedium),
        ],
      ),
    );
  }
}
