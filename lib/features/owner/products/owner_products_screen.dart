import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/product.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/ui/image_placeholder.dart';
import '../../../core/ui/ls_theme.dart';
import '../../../core/ui/price_text.dart';
import '../../../core/ui/skeleton.dart';
import '../../../core/ui/stock_label.dart';
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
                          return _ProductRow(
                            product: p,
                            onTap: () =>
                                context.push('/owner/products/${p.id}'),
                            onEditStock: () => _editStock(p),
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

/// ProductRow, owner variant: 56dp thumbnail, name, category, stock, price
/// with its unit, and an Active/Hidden tag in place of Add.
class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.onTap,
    required this.onEditStock,
  });

  final AdminProduct product;
  final VoidCallback onTap;
  final VoidCallback onEditStock;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final p = product;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: ProductImage(
                  url: p.imageUrl,
                  iconSize: 24,
                  name: p.name,
                  category: p.category.name,
                  dim: p.stockQty <= 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _StatusTag(active: p.isActive),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StockLabel(qty: p.stockQty, unit: p.unit),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(p.price, unit: p.unit, size: PriceSize.md),
                const SizedBox(height: 4),
                IconButton(
                  tooltip: 'Edit stock',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: onEditStock,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ls = lsColorsOf(theme);
    final bg = active ? ls.successContainer : ls.neutralContainer;
    final fg = active ? ls.onSuccessContainer : ls.onNeutralContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        active ? 'Active' : 'Hidden',
        style: theme.textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
