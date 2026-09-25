import 'package:flutter/material.dart';

/// Titled block used on detail screens (SectionHeader: `space-6` above,
/// `space-2` below, optional count and text action).
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.trailing,
  });

  final String title;
  final Widget child;

  /// Muted count shown after the title.
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: text.titleMedium),
              if (count != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    '$count',
                    style: text.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// `label ........ value` row for totals.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final Widget value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize ? text.titleMedium : text.bodyMedium,
            ),
          ),
          value,
        ],
      ),
    );
  }
}
