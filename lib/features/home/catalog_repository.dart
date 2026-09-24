import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/category.dart';
import '../../core/models/json.dart';
import '../../core/models/paged.dart';
import '../../core/models/product.dart';
import '../../core/models/store.dart';

/// Public catalog reads: `/store`, `/categories`, `/products`.
class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<StoreInfo> store() async =>
      StoreInfo.fromJson(asJson(await _api.get('/store', noAuth: true)));

  Future<List<Category>> categories() async =>
      asJsonList(await _api.get('/categories', noAuth: true))
          .map(Category.fromJson)
          .toList(growable: false);

  Future<Paged<ProductSummary>> products({
    String? category,
    String? q,
    bool? inStock,
    String? cursor,
    int? limit,
  }) async => Paged.fromJson(
    asJson(
      await _api.get(
        '/products',
        query: {
          'category': category,
          'q': q,
          'inStock': inStock == true ? 'true' : null,
          'cursor': cursor,
          'limit': limit,
        },
        noAuth: true,
      ),
    ),
    ProductSummary.fromJson,
  );

  Future<Product> product(String id) async =>
      Product.fromJson(asJson(await _api.get('/products/$id', noAuth: true)));
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(apiClientProvider)),
);
