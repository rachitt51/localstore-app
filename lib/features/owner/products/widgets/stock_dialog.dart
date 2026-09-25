import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/models/product.dart';
import '../owner_products_repository.dart';

/// Small dialog: pick a variant (when several), enter the absolute stock,
/// `PATCH /admin/products/:id/stock {variantId?, absolute}`. Resolves to the
/// updated product or null.
Future<AdminProduct?> showStockDialog(
  BuildContext context,
  WidgetRef ref, {
  required AdminProduct product,
}) {
  return showDialog<AdminProduct>(
    context: context,
    builder: (_) => _StockDialog(product: product),
  );
}

class _StockDialog extends ConsumerStatefulWidget {
  const _StockDialog({required this.product});

  final AdminProduct product;

  @override
  ConsumerState<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends ConsumerState<_StockDialog> {
  late String? _variantId = widget.product.variants.isEmpty
      ? null
      : widget.product.variants.first.id;
  late final _qty = TextEditingController(
    text: '${_currentVariant?.stockQty ?? widget.product.stockQty}',
  );
  bool _saving = false;
  String? _error;

  Variant? get _currentVariant {
    for (final v in widget.product.variants) {
      if (v.id == _variantId) return v;
    }
    return null;
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = int.tryParse(_qty.text.trim());
    if (qty == null || qty < 0) {
      setState(() => _error = 'Enter a whole number');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(ownerProductsRepositoryProvider)
          .setStock(
            widget.product.id,
            variantId: widget.product.variants.length > 1 ? _variantId : null,
            absolute: qty,
          );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final variants = widget.product.variants;
    return AlertDialog(
      title: Text(widget.product.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (variants.length > 1) ...[
            DropdownButtonFormField<String>(
              initialValue: _variantId,
              decoration: const InputDecoration(labelText: 'Variant'),
              items: [
                for (final v in variants)
                  DropdownMenuItem(
                    value: v.id,
                    child: Text('${v.name} (${v.stockQty})'),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (id) => setState(() {
                      _variantId = id;
                      _qty.text = '${_currentVariant?.stockQty ?? 0}';
                    }),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _qty,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Stock (${widget.product.unit})',
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
