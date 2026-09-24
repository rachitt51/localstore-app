import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/json.dart';
import '../../../core/models/order.dart';
import '../../../core/models/paged.dart';

/// `/admin/orders`.
class OwnerOrdersRepository {
  OwnerOrdersRepository(this._api);

  final ApiClient _api;

  Future<OrdersSummary> summary() async =>
      OrdersSummary.fromJson(asJson(await _api.get('/admin/orders/summary')));

  /// [statuses] empty → the API default (everything not terminal).
  Future<Paged<AdminOrderSummary>> list({
    List<String> statuses = const [],
    String? cursor,
    int? limit,
  }) async => Paged.fromJson(
    asJson(
      await _api.get(
        '/admin/orders',
        query: {
          'status': statuses.isEmpty ? null : statuses.join(','),
          'cursor': cursor,
          'limit': limit,
        },
      ),
    ),
    AdminOrderSummary.fromJson,
  );

  Future<AdminOrder> get(String id) async =>
      AdminOrder.fromJson(asJson(await _api.get('/admin/orders/$id')));

  Future<AdminOrder> transition(
    String id, {
    required String to,
    String? note,
    int? etaMinutes,
  }) async => AdminOrder.fromJson(
    asJson(
      await _api.post(
        '/admin/orders/$id/transition',
        body: {
          'to': to,
          if (note != null && note.isNotEmpty) 'note': note,
          'etaMinutes': ?etaMinutes,
        },
      ),
    ),
  );
}

final ownerOrdersRepositoryProvider = Provider<OwnerOrdersRepository>(
  (ref) => OwnerOrdersRepository(ref.watch(apiClientProvider)),
);
