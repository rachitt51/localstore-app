import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `−  n  +` bounded by [min]/[max], with the trade unit beside the number.
/// Tapping the number opens numeric entry for bulk quantities.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
    this.unit,
    this.enabled = true,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;

  /// Shown muted after the number (`12 sheets`).
  final String? unit;
  final bool enabled;
  final bool compact;

  Future<void> _editValue(BuildContext context) async {
    final controller = TextEditingController(text: '$value');
    final entered = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quantity'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(suffixText: unit),
          onSubmitted: (v) => Navigator.of(context).pop(int.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text)),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (entered == null) return;
    final clamped = entered < min
        ? min
        : (max != null && entered > max! ? max! : entered);
    if (clamped != value) onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final canDec = enabled && value > min;
    final canInc = enabled && (max == null || value < max!);
    final size = compact ? 40.0 : 48.0;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease quantity',
            iconSize: compact ? 18 : 22,
            constraints: BoxConstraints.tightFor(width: size, height: size),
            onPressed: canDec ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          InkWell(
            onTap: enabled ? () => _editValue(context) : null,
            borderRadius: BorderRadius.circular(4),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: 28, minHeight: size),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (unit != null && unit!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit!,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            iconSize: compact ? 18 : 22,
            constraints: BoxConstraints.tightFor(width: size, height: size),
            onPressed: canInc ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
