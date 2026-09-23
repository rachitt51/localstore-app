import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/session.dart';
import '../../core/models/cart.dart';
import 'cart_repository.dart';

/// Server-authoritative cart. Empty while a guest; reloads on sign-in.
class CartNotifier extends AsyncNotifier<Cart> {
  @override
  Future<Cart> build() async {
    final signedIn = ref.watch(sessionProvider.select((s) => s.isSignedIn));
    if (!signedIn) return Cart.empty;
    return ref.read(cartRepositoryProvider).get();
  }

  Future<void> refresh() async {
    if (!ref.read(sessionProvider).isSignedIn) return;
    state = await AsyncValue.guard(ref.read(cartRepositoryProvider).get);
  }

  /// Adds [qty] on top of the current line quantity.
  Future<void> add(String variantId, int qty) async {
    final current = state.value?.items
        .where((l) => l.variantId == variantId)
        .fold(0, (sum, l) => sum + l.qty);
    await setQty(variantId, (current ?? 0) + qty);
  }

  /// Sets the line quantity; 0 removes the line. Throws [ApiException] on
  /// failure so the caller can show the message inline.
  Future<void> setQty(String variantId, int qty) async {
    final repo = ref.read(cartRepositoryProvider);
    final cart = qty <= 0
        ? await repo.removeItem(variantId)
        : await repo.setItem(variantId, qty);
    state = AsyncData(cart);
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, Cart>(
  CartNotifier.new,
);

/// Badge count for the app bar; cheap to watch.
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).value?.itemCount ?? 0,
);
