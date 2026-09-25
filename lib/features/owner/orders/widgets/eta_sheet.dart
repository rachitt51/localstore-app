import 'package:flutter/material.dart';

import '../../../../core/ui/format.dart';

const _quickPicks = [30, 45, 60, 90, 120];
const _defaultMinutes = 45;

/// Asks for `etaMinutes` (1-1440): quick picks or a custom time picked on
/// the clock. The resolved absolute time is shown in words so the owner
/// confirms what the customer will see as a countdown.
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
  int _minutes = _defaultMinutes;

  DateTime get _etaAt => DateTime.now().add(Duration(minutes: _minutes));

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(Duration(minutes: _minutes))),
    );
    if (picked == null || !mounted) return;
    var eta = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    if (!eta.isAfter(now)) eta = eta.add(const Duration(days: 1));
    setState(() => _minutes = eta.difference(now).inMinutes.clamp(1, 1440));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final custom = !_quickPicks.contains(_minutes);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Estimated time to delivery', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _quickPicks)
                ChoiceChip(
                  label: Text('$m min'),
                  selected: _minutes == m,
                  selectedColor: scheme.secondaryContainer,
                  onSelected: (_) => setState(() => _minutes = m),
                ),
              ChoiceChip(
                label: const Text('Custom'),
                selected: custom,
                selectedColor: scheme.secondaryContainer,
                onSelected: (_) => _pickCustom(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Arrives around ${formatTime(_etaAt)}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(64, 40)),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
                onPressed: () => Navigator.of(context).pop(_minutes),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
