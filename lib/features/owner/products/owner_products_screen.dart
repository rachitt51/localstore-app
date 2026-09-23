import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/product.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/ui/image_placeholder.dart';
import '../../../core/ui/price_text.dart';
import '../../../core/ui/skeleton.dart';
import 'owner_products_repository.dart';
import 'widgets/stock_dialog.dart';

/// `/owner/products`: search, list with inline stock edit, FAB to add.
class OwnerProductsScreen extends ConsumerStatefulWidget {
  const OwnerProductsScreen({super.key});

  @override
  ConsumerState<OwnerProductsScreen> createState() =>
      _OwnerProductsScreenState();
}

class _OwnerProductsScreenState extends ConsumerState<OwnerProductsScreen> {
  final _search = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _editStock(AdminProduct product) async {
    final updated = await showStockDialog(context, ref, product: product);
    if (updated != null) {
      ref.read(ownerProductListProvider(_query).notifier).replace(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(ownerProductListProvider(_query));
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'New product',
        onPressed: () => context.push('/owner/products/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search products',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: products.when(
              data: (page) => page.items.isEmpty
                  ? const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No products',
                      message: 'Add your first product with the + button.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(ownerProductListProvider(_query).notifier)
                          .refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: page.items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final p = page.items[i];
                          return ListTile(
                            onTap: () =>
                                context.push('/owner/products/${p.id}'),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: ProductImage(
                                  url: p.imageUrl,
                                  iconSize: 20,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!p.isActive)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Inactive',
                                      style: text.labelSmall,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PriceText(
                                  p.price,
                                  unit: p.unit,
                                  style: text.bodyMedium,
                                ),
                              ],
                            ),
                            trailing: TextButton.icon(
                              onPressed: () => _editStock(p),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: Text(
                                '${p.stockQty}',
                                style: text.titleMedium?.copyWith(
                                  color: p.stockQty > 0
                                      ? scheme.primary
                                      : scheme.error,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              loading: () => const SkeletonList(),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(ownerProductListProvider(_query)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
