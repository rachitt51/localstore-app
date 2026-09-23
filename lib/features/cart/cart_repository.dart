import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/cart.dart';
import '../../core/models/json.dart';

class CartRepository {
  CartRepository(this._api);

  final ApiClient _api;

  Future<Cart> get() async => Cart.fromJson(asJson(await _api.get('/cart')));

  /// Upsert one line; `qty = 0` removes it.
  Future<Cart> setItem(String variantId, int qty) async => Cart.fromJson(
    asJson(
      await _api.post(
        '/cart/items',
        body: {'variantId': variantId, 'qty': qty},
      ),
    ),
  );

  Future<Cart> removeItem(String variantId) async =>
      Cart.fromJson(asJson(await _api.delete('/cart/items/$variantId')));

  Future<Cart> replace(List<({String variantId, int qty})> items) async =>
      Cart.fromJson(
        asJson(
          await _api.put(
            '/cart',
            body: {
              'items': [
                for (final i in items) {'variantId': i.variantId, 'qty': i.qty},
              ],
            },
          ),
        ),
      );
}

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(ref.watch(apiClientProvider)),
);
