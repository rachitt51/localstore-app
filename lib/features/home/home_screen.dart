import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/session.dart';
import '../../core/models/product.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/product_card.dart';
import '../../core/ui/skeleton.dart';
import '../account/account_menu.dart';
import '../cart/cart_notifier.dart';
import '../cart/widgets/cart_action.dart';
import 'catalog_repository.dart';
import 'home_providers.dart';
import 'widgets/store_banner.dart';

/// Storefront: store banner, search, category chips, product grid.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(homeQueryProvider.notifier).setSearch(value);
    });
  }

  /// Adds one unit of [product]'s default variant and shows a SnackBar with
  /// Undo (ProductCard: "Quick-add adds one unit of the default variant").
  Future<void> _quickAdd(ProductSummary product) async {
    if (!ref.read(sessionProvider).isSignedIn) {
      context.push('/login?from=${Uri.encodeComponent('/')}');
      return;
    }
    try {
      final full = await ref
          .read(catalogRepositoryProvider)
          .product(product.id);
      final variants = full.activeVariants;
      final variant = variants.isEmpty
          ? null
          : variants.firstWhere((v) => v.inStock, orElse: () => variants.first);
      if (variant == null || !variant.inStock) return;
      final previousQty =
          ref
              .read(cartProvider)
              .value
              ?.items
              .where((l) => l.variantId == variant.id)
              .fold(0, (sum, l) => sum + l.qty) ??
          0;
      await ref.read(cartProvider.notifier).add(variant.id, 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: const Text('Added to cart'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => ref
                  .read(cartProvider.notifier)
                  .setQty(variant.id, previousQty),
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(homeQueryProvider);
    final products = ref.watch(productListProvider(query));
    final categories = ref.watch(categoriesProvider);
    final store = ref.watch(storeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(store.value?.name ?? 'LocalStore'),
        actions: const [CartAction(), AccountMenuButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(storeProvider);
          ref.invalidate(categoriesProvider);
          await ref.read(productListProvider(query).notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: store.when(
                data: (s) => StoreBanner(store: s),
                loading: () => const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Skeleton(height: 64, radius: 8),
                ),
                error: (e, _) => StoreBannerError(
                  onRetry: () => ref.invalidate(storeProvider),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search plywood, laminates, hardware…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.q.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              _debounce?.cancel();
                              ref
                                  .read(homeQueryProvider.notifier)
                                  .setSearch('');
                            },
                          ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: categories.when(
                data: (list) => SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: query.category == null,
                          onSelected: (_) => ref
                              .read(homeQueryProvider.notifier)
                              .setCategory(null),
                        ),
                      ),
                      for (final c in list)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(c.name),
                            selected: query.category == c.slug,
                            onSelected: (selected) => ref
                                .read(homeQueryProvider.notifier)
                                .setCategory(selected ? c.slug : null),
                          ),
                        ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(height: 48),
                error: (_, _) => const SizedBox(height: 8),
              ),
            ),
            ...products.when(
              data: (page) => [
                if (page.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'No products found',
                      message: query.q.isEmpty
                          ? 'Nothing listed in this category yet.'
                          : 'Try a different search.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.72,
                          ),
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final ProductSummary p = page.items[i];
                        return ProductCard(
                          product: p,
                          onTap: () => context.push('/products/${p.id}'),
                          onQuickAdd: p.inStock ? () => _quickAdd(p) : null,
                        );
                      }, childCount: page.items.length),
                    ),
                  ),
                if (page.hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: () => ref
                              .read(productListProvider(query).notifier)
                              .loadMore(),
                          child: const Text('Load more'),
                        ),
                      ),
                    ),
                  ),
              ],
              loading: () => const [
                // SkeletonGrid is itself a viewport, so it needs a scroll body.
                SliverFillRemaining(child: SkeletonGrid()),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(
                    error: e,
                    onRetry: () => ref.invalidate(productListProvider(query)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
