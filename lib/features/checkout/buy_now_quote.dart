import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/cart.dart';
import '../../core/ui/format.dart';
import '../orders/orders_repository.dart';
import 'checkout_draft.dart';

/// `POST /orders/quote` for the Buy-now lines in the checkout draft.
/// Re-fetches when the lines or the selected address change; `null` when the
/// draft is a cart checkout (the cart already carries its totals).
final buyNowQuoteProvider = FutureProvider.autoDispose<Quote?>((ref) async {
  final (items, addressId) = ref.watch(
    checkoutDraftProvider.select((d) => (d.pendingItems, d.address?.id)),
  );
  if (items == null) return null;
  return ref.read(ordersRepositoryProvider).quote([
    for (final i in items) (variantId: i.variantId, qty: i.qty),
  ], addressId: addressId);
});

/// Human wording for `Quote.codReason`. [codMaxAmount] is the store's cap
/// (money string, `GET /store`) quoted for `ABOVE_COD_MAX`.
String codReasonMessage(String? reason, {String? codMaxAmount}) {
  if (reason == 'ABOVE_COD_MAX' && codMaxAmount != null) {
    return 'Cash on delivery is only available up to '
        '${formatInr(codMaxAmount)}';
  }
  return 'Cash on delivery is not available';
}
