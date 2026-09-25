import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/product.dart';
import '../../../core/ui/back_or_home_button.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/ui/image_placeholder.dart';
import '../../../core/ui/skeleton.dart';
import 'owner_products_repository.dart';

/// `/owner/products/new` and `/owner/products/:id`.
class ProductFormScreen extends ConsumerWidget {
  const ProductFormScreen({super.key, this.productId});

  /// null → create.
  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = productId;
    if (id == null) return const _ProductForm(existing: null);
    final product = ref.watch(ownerProductProvider(id));
    return product.when(
      data: (p) => _ProductForm(existing: p),
      loading: () => Scaffold(
        appBar: AppBar(
          leading: const BackOrHomeButton(fallback: '/owner/products'),
          title: const Text('Product'),
        ),
        body: const SkeletonList(rows: 6),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          leading: const BackOrHomeButton(fallback: '/owner/products'),
          title: const Text('Product'),
        ),
        body: ErrorState(
          error: e,
          onRetry: () => ref.invalidate(ownerProductProvider(id)),
        ),
      ),
    );
  }
}

class _VariantRow {
  _VariantRow({
    this.id,
    String name = '',
    String sku = '',
    String priceDelta = '',
    String stockQty = '0',
    this.isActive = true,
  }) : name = TextEditingController(text: name),
       sku = TextEditingController(text: sku),
       priceDelta = TextEditingController(text: priceDelta),
       stockQty = TextEditingController(text: stockQty);

  factory _VariantRow.from(Variant v) => _VariantRow(
    id: v.id,
    name: v.name,
    sku: v.sku ?? '',
    priceDelta: v.priceDelta ?? '',
    stockQty: '${v.stockQty}',
    isActive: v.isActive,
  );

  final String? id;
  final TextEditingController name;
  final TextEditingController sku;
  final TextEditingController priceDelta;
  final TextEditingController stockQty;
  bool isActive;

  void dispose() {
    name.dispose();
    sku.dispose();
    priceDelta.dispose();
    stockQty.dispose();
  }

  VariantInput toInput() => VariantInput(
    id: id,
    name: name.text.trim(),
    sku: sku.text.trim(),
    priceDelta: priceDelta.text.trim(),
    stockQty: int.tryParse(stockQty.text.trim()) ?? 0,
    isActive: isActive,
  );
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({required this.existing});

  final AdminProduct? existing;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _description = TextEditingController(
    text: widget.existing?.description,
  );
  late final _unit = TextEditingController(text: widget.existing?.unit);
  late final _basePrice = TextEditingController(
    text: widget.existing?.basePrice,
  );
  final _stockQty = TextEditingController(text: '0');
  late String? _categoryId = widget.existing?.categoryId;
  late bool _autoApprove = widget.existing?.autoApprove ?? false;
  late bool _isActive = widget.existing?.isActive ?? true;
  late final List<String> _images = [...?widget.existing?.images];
  late final List<_VariantRow> _variants = [
    for (final v in widget.existing?.variants ?? const <Variant>[])
      _VariantRow.from(v),
  ];
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _description, _unit, _basePrice, _stockQty]) {
      c.dispose();
    }
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _addImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await ref
          .read(ownerProductsRepositoryProvider)
          .upload(file.path);
      setState(() => _images.add(url));
    } catch (e) {
      setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _error = 'Choose a category');
      return;
    }
    for (final v in _variants) {
      if (v.name.text.trim().isEmpty) {
        setState(() => _error = 'Every variant needs a name');
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'categoryId': _categoryId,
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'basePrice': _basePrice.text.trim(),
      'unit': _unit.text.trim(),
      'images': _images,
      'autoApprove': _autoApprove,
      'isActive': _isActive,
    };
    final repo = ref.read(ownerProductsRepositoryProvider);
    try {
      final existing = widget.existing;
      if (existing == null) {
        if (_variants.isEmpty) {
          body['stockQty'] = int.tryParse(_stockQty.text.trim()) ?? 0;
        } else {
          body['variants'] = [for (final v in _variants) v.toInput().toJson()];
        }
        await repo.create(body);
      } else {
        await repo.update(existing.id, body);
        if (_variants.isNotEmpty) {
          await repo.setVariants(existing.id, [
            for (final v in _variants) v.toInput(),
          ]);
        }
        ref.invalidate(ownerProductProvider(existing.id));
      }
      ref.invalidate(ownerProductListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing == null ? 'Product added' : 'Saved')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/owner/products');
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(ownerCategoriesProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isNew = widget.existing == null;
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(fallback: '/owner/products'),
        title: Text(isNew ? 'New product' : 'Edit product'),
        actions: [
          TextButton(
            onPressed: _saving || _uploading ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            categories.when(
              data: (list) => DropdownButtonFormField<String>(
                initialValue: list.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in list)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (id) => setState(() => _categoryId = id),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                'Categories: ${errorMessage(e)}',
                style: text.bodySmall?.copyWith(color: scheme.error),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      hintText: 'sheet, litre, box…',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _basePrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Base price',
                      prefixText: '₹ ',
                    ),
                    validator: (v) =>
                        (v == null || !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v))
                        ? 'e.g. 2450 or 2450.00'
                        : null,
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-approve orders'),
              subtitle: const Text(
                'Orders with only auto-approve items skip the Accept step',
              ),
              value: _autoApprove,
              onChanged: (v) => setState(() => _autoApprove = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: const Text(
                'Inactive products are hidden from customers',
              ),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 16),
            Text('Images', style: text.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _images.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: ProductImage(url: _images[i]),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton.filledTonal(
                          tooltip: 'Remove image',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() => _images.removeAt(i)),
                        ),
                      ),
                    ],
                  ),
                SizedBox(
                  width: 96,
                  height: 96,
                  child: OutlinedButton(
                    onPressed: _uploading ? null : _addImage,
                    child: _uploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined),
                              SizedBox(height: 4),
                              Text('Add image', textAlign: TextAlign.center),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Text('Variants', style: text.titleMedium)),
                TextButton.icon(
                  onPressed: () => setState(
                    () => _variants.add(
                      _VariantRow(name: _variants.isEmpty ? 'Default' : ''),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add variant'),
                ),
              ],
            ),
            if (_variants.isEmpty) ...[
              Text(
                isNew
                    ? 'No variants: a single "Default" variant is created.'
                    : 'Variants unchanged.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (isNew) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _stockQty,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Stock'),
                ),
              ],
            ] else
              for (var i = 0; i < _variants.length; i++)
                _VariantCard(
                  row: _variants[i],
                  onRemove: () => setState(() {
                    _variants.removeAt(i).dispose();
                  }),
                  onActiveChanged: (v) =>
                      setState(() => _variants[i].isActive = v),
                ),
            InlineError(_error),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving || _uploading ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save product'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.row,
    required this.onRemove,
    required this.onActiveChanged,
  });

  final _VariantRow row;
  final VoidCallback onRemove;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: row.name,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: row.sku,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove variant',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: row.priceDelta,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[-\d.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Price delta',
                      prefixText: '₹ ',
                      hintText: '0.00',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: row.stockQty,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Stock'),
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  children: [
                    Text(
                      'Active',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Switch(value: row.isActive, onChanged: onActiveChanged),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
