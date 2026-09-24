import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/product.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/product_card.dart';
import '../../core/ui/skeleton.dart';
import '../account/account_menu.dart';
import '../cart/widgets/cart_action.dart';
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
                  child: Skeleton(height: 64, radius: 12),
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
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
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
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final ProductSummary p = page.items[i];
                        return ProductCard(
                          product: p,
                          onTap: () => context.push('/products/${p.id}'),
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
