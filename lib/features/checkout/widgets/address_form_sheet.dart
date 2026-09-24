import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/address.dart';
import '../../../core/ui/error_state.dart';
import '../../account/addresses_repository.dart';

/// Add / edit form for `POST|PATCH /me/addresses`. Pops with the saved
/// [Address].
class AddressFormSheet extends ConsumerStatefulWidget {
  const AddressFormSheet({super.key, this.existing});

  final Address? existing;

  @override
  ConsumerState<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<AddressFormSheet> {
  final _form = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.existing?.label);
  late final _line1 = TextEditingController(text: widget.existing?.line1);
  late final _line2 = TextEditingController(text: widget.existing?.line2);
  late final _landmark = TextEditingController(text: widget.existing?.landmark);
  late final _pincode = TextEditingController(text: widget.existing?.pincode);
  late bool _isDefault = widget.existing?.isDefault ?? false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_label, _line1, _line2, _landmark, _pincode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(addressesProvider.notifier)
          .save(
            id: widget.existing?.id,
            body: {
              'label': _label.text.trim(),
              'line1': _line1.text.trim(),
              'line2': _line2.text.trim().isEmpty ? null : _line2.text.trim(),
              'landmark': _landmark.text.trim().isEmpty
                  ? null
                  : _landmark.text.trim(),
              'pincode': _pincode.text.trim(),
              'isDefault': _isDefault,
            },
          );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = errorMessage(e);
      });
    }
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(addressesProvider.notifier).delete(id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = errorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'New address' : 'Edit address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _label,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'Site, Office, Warehouse…',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _line1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Address line 1'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _line2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Address line 2 (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _landmark,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Landmark (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pincode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(labelText: 'Pincode'),
                validator: (v) => (v == null || !RegExp(r'^\d{6}$').hasMatch(v))
                    ? 'Enter a 6-digit pincode'
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use as default'),
                value: _isDefault,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _isDefault = v),
              ),
              InlineError(_error),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.existing != null)
                    TextButton(
                      onPressed: _saving ? null : _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
