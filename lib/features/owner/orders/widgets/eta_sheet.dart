import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _quickPicks = [30, 45, 60, 90, 120];

/// Asks for `etaMinutes` (1–1440) with quick picks and a custom field.
Future<int?> showEtaSheet(BuildContext context, {required String title}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EtaSheet(title: title),
  );
}

class _EtaSheet extends StatefulWidget {
  const _EtaSheet({required this.title});

  final String title;

  @override
  State<_EtaSheet> createState() => _EtaSheetState();
}

class _EtaSheetState extends State<_EtaSheet> {
  final _custom = TextEditingController();
  int? _selected = 45;
  String? _error;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _submit() {
    final custom = int.tryParse(_custom.text.trim());
    final value = custom ?? _selected;
    if (value == null || value < 1 || value > 1440) {
      setState(() => _error = 'Enter 1 to 1440 minutes');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Estimated time to delivery',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _quickPicks)
                ChoiceChip(
                  label: Text('$m min'),
                  selected: _selected == m && _custom.text.isEmpty,
                  onSelected: (_) => setState(() {
                    _selected = m;
                    _custom.clear();
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _custom,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: 'Custom (minutes)',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _submit, child: const Text('Confirm')),
            ],
          ),
        ],
      ),
    );
  }
}
