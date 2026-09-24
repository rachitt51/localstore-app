import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/category.dart';
import '../../core/models/paged.dart';
import '../../core/models/product.dart';
import '../../core/models/store.dart';
import 'catalog_repository.dart';

final storeProvider = FutureProvider<StoreInfo>(
  (ref) => ref.watch(catalogRepositoryProvider).store(),
);

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

/// What the home grid is showing: free-text search and/or a category slug.
typedef ProductQuery = ({String q, String? category});

class HomeQueryNotifier extends Notifier<ProductQuery> {
  @override
  ProductQuery build() => (q: '', category: null);

  void setSearch(String q) => state = (q: q.trim(), category: state.category);

  void setCategory(String? slug) => state = (q: state.q, category: slug);
}

final homeQueryProvider = NotifierProvider<HomeQueryNotifier, ProductQuery>(
  HomeQueryNotifier.new,
);

/// Paged product list for one query; `loadMore` appends the next cursor page.
class ProductListNotifier extends AsyncNotifier<Paged<ProductSummary>> {
  ProductListNotifier(this.query);

  final ProductQuery query;

  @override
  Future<Paged<ProductSummary>> build() => _fetch();

  Future<Paged<ProductSummary>> _fetch({String? cursor}) => ref
      .read(catalogRepositoryProvider)
      .products(
        q: query.q.isEmpty ? null : query.q,
        category: query.category,
        cursor: cursor,
      );

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
}

final productListProvider = AsyncNotifierProvider.autoDispose
    .family<ProductListNotifier, Paged<ProductSummary>, ProductQuery>(
      ProductListNotifier.new,
    );

final productProvider = FutureProvider.autoDispose.family<Product, String>(
  (ref, id) => ref.watch(catalogRepositoryProvider).product(id),
);
