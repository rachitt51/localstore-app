import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/address.dart';
import '../../core/models/order.dart';

/// A Buy-now line: what to order plus what to show on the checkout summary.
/// Prices are the API's variant price at the time of tapping; the order
/// total is computed by the API when the order is placed.
class PendingItem {
  const PendingItem({
    required this.variantId,
    required this.qty,
    required this.name,
    this.variantName,
    required this.unit,
    required this.unitPrice,
    this.imageUrl,
  });

  final String variantId;
  final int qty;
  final String name;
  final String? variantName;
  final String unit;
  final String unitPrice;
  final String? imageUrl;
}

/// What the address → checkout → payment funnel is working on.
class CheckoutDraft {
  const CheckoutDraft({
    this.pendingItems,
    this.address,
    this.paymentMethod = PaymentMethod.cod,
    this.notes = '',
  });

  /// `null` means "order the cart"; a list means Buy now (cart untouched).
  final List<PendingItem>? pendingItems;
  final Address? address;
  final String paymentMethod;
  final String notes;

  bool get isBuyNow => pendingItems != null;

  CheckoutDraft copyWith({
    List<PendingItem>? pendingItems,
    bool clearPendingItems = false,
    Address? address,
    String? paymentMethod,
    String? notes,
  }) => CheckoutDraft(
    pendingItems: clearPendingItems ? null : pendingItems ?? this.pendingItems,
    address: address ?? this.address,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    notes: notes ?? this.notes,
  );
}

class CheckoutDraftNotifier extends Notifier<CheckoutDraft> {
  @override
  CheckoutDraft build() => const CheckoutDraft();

  /// Checkout from the cart.
  void startFromCart() =>
      state = CheckoutDraft(address: state.address, notes: state.notes);

  /// Buy now: skip the cart with exactly these lines.
  void startBuyNow(List<PendingItem> items) =>
      state = CheckoutDraft(pendingItems: items, address: state.address);

  void selectAddress(Address address) =>
      state = state.copyWith(address: address);

  void setPaymentMethod(String method) =>
      state = state.copyWith(paymentMethod: method);

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  /// Keep the address for next time; drop the lines and notes.
  void clearAfterOrder() => state = CheckoutDraft(address: state.address);
}

final checkoutDraftProvider =
    NotifierProvider<CheckoutDraftNotifier, CheckoutDraft>(
      CheckoutDraftNotifier.new,
    );
