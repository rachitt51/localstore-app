import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/cart.dart';
import '../../core/models/json.dart';
import '../../core/models/order.dart';
import '../../core/models/paged.dart';

/// One `{variantId, qty}` for a Buy-now order.
typedef OrderItemInput = ({String variantId, int qty});

/// Customer `/orders`.
class OrdersRepository {
  OrdersRepository(this._api);

  final ApiClient _api;

  Future<Paged<OrderSummary>> list({String? cursor, int? limit}) async =>
      Paged.fromJson(
        asJson(
          await _api.get('/orders', query: {'cursor': cursor, 'limit': limit}),
        ),
        OrderSummary.fromJson,
      );

  Future<Order> get(String id) async =>
      Order.fromJson(asJson(await _api.get('/orders/$id')));

  /// `items == null` orders the cart (and clears it); otherwise exactly
  /// [items] and the cart is untouched.
  Future<Order> create({
    required String addressId,
    required String paymentMethod,
    String? notes,
    List<OrderItemInput>? items,
  }) async => Order.fromJson(
    asJson(
      await _api.post(
        '/orders',
        body: {
          'addressId': addressId,
          'paymentMethod': paymentMethod,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (items != null)
            'items': [
              for (final i in items) {'variantId': i.variantId, 'qty': i.qty},
            ],
        },
      ),
    ),
  );

  /// Prices [items] exactly as [create] would, without creating anything.
  /// Used by the Buy-now checkout to show the total before placing.
  Future<Quote> quote(List<OrderItemInput> items, {String? addressId}) async =>
      Quote.fromJson(
        asJson(
          await _api.post(
            '/orders/quote',
            body: {
              'items': [
                for (final i in items) {'variantId': i.variantId, 'qty': i.qty},
              ],
              'addressId': ?addressId,
            },
          ),
        ),
      );

  Future<Order> cancel(String id, {String? reason}) async => Order.fromJson(
    asJson(
      await _api.post(
        '/orders/$id/cancel',
        body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      ),
    ),
  );

  /// Dev-only mock gateway. [outcome] is `success` or `failure`.
  Future<Order> mockConfirm(String id, {required String outcome}) async =>
      Order.fromJson(
        asJson(
          await _api.post(
            '/orders/$id/payment/mock-confirm',
            body: {'outcome': outcome},
          ),
        ),
      );
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref.watch(apiClientProvider)),
);
