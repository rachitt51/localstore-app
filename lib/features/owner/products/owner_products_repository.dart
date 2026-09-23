import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/category.dart';
import '../../../core/models/json.dart';
import '../../../core/models/paged.dart';
import '../../../core/models/product.dart';

/// One row of `PUT /admin/products/:id/variants`.
class VariantInput {
  const VariantInput({
    this.id,
    required this.name,
    this.sku,
    this.priceDelta,
    required this.stockQty,
    this.isActive = true,
  });

  final String? id;
  final String name;
  final String? sku;

  /// Money string; null → API default `0.00`.
  final String? priceDelta;
  final int stockQty;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    if (sku != null && sku!.isNotEmpty) 'sku': sku,
    if (priceDelta != null && priceDelta!.isNotEmpty) 'priceDelta': priceDelta,
    'stockQty': stockQty,
    'isActive': isActive,
  };
}

/// `/admin/products`, `/admin/categories`, `/admin/uploads`.
class OwnerProductsRepository {
  OwnerProductsRepository(this._api);

  final ApiClient _api;

  Future<List<Category>> categories() async =>
      asJsonList(await _api.get('/admin/categories'))
          .map(Category.fromJson)
          .toList(growable: false);

  Future<Paged<AdminProduct>> list({
    String? q,
    String? category,
    bool includeInactive = true,
    String? cursor,
    int? limit,
  }) async => Paged.fromJson(
    asJson(
      await _api.get(
        '/admin/products',
        query: {
          'q': q,
          'category': category,
          'includeInactive': includeInactive ? 'true' : null,
          'cursor': cursor,
          'limit': limit,
        },
      ),
    ),
    AdminProduct.fromJson,
  );

  Future<AdminProduct> get(String id) async =>
      AdminProduct.fromJson(asJson(await _api.get('/admin/products/$id')));

  Future<AdminProduct> create(Map<String, dynamic> body) async =>
      AdminProduct.fromJson(
        asJson(await _api.post('/admin/products', body: body)),
      );

  Future<AdminProduct> update(String id, Map<String, dynamic> body) async =>
      AdminProduct.fromJson(
        asJson(await _api.patch('/admin/products/$id', body: body)),
      );

  Future<AdminProduct> setVariants(
    String id,
    List<VariantInput> variants,
  ) async => AdminProduct.fromJson(
    asJson(
      await _api.put(
        '/admin/products/$id/variants',
        body: [for (final v in variants) v.toJson()],
      ),
    ),
  );

  Future<AdminProduct> setStock(
    String id, {
    String? variantId,
    int? absolute,
    int? delta,
  }) async => AdminProduct.fromJson(
    asJson(
      await _api.patch(
        '/admin/products/$id/stock',
        body: {'variantId': ?variantId, 'absolute': ?absolute, 'delta': ?delta},
      ),
    ),
  );

  /// Returns the absolute image URL.
  Future<String> upload(String filePath) async {
    final json = asJson(await _api.upload('/admin/uploads', filePath));
    return asString(json['url']);
  }
}

final ownerProductsRepositoryProvider = Provider<OwnerProductsRepository>(
  (ref) => OwnerProductsRepository(ref.watch(apiClientProvider)),
);

final ownerCategoriesProvider = FutureProvider.autoDispose<List<Category>>(
  (ref) => ref.watch(ownerProductsRepositoryProvider).categories(),
);

final ownerProductProvider = FutureProvider.autoDispose
    .family<AdminProduct, String>(
      (ref, id) => ref.watch(ownerProductsRepositoryProvider).get(id),
    );

/// Owner product list for one search string; `refresh` after edits.
class OwnerProductListNotifier extends AsyncNotifier<Paged<AdminProduct>> {
  OwnerProductListNotifier(this.query);

  final String query;

  @override
  Future<Paged<AdminProduct>> build() => _fetch();

  Future<Paged<AdminProduct>> _fetch({String? cursor}) => ref
      .read(ownerProductsRepositoryProvider)
      .list(q: query.isEmpty ? null : query, cursor: cursor, limit: 50);

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || state.isLoading) return;
    final next = await AsyncValue.guard(
      () => _fetch(cursor: current.nextCursor),
    );
    state = next.whenData(current.append);
  }

  /// Replace one row after a stock edit without refetching.
  void replace(AdminProduct product) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      Paged(
        items: [
          for (final p in current.items) p.id == product.id ? product : p,
        ],
        nextCursor: current.nextCursor,
      ),
    );
  }
}

final ownerProductListProvider = AsyncNotifierProvider.autoDispose
    .family<OwnerProductListNotifier, Paged<AdminProduct>, String>(
      OwnerProductListNotifier.new,
    );
