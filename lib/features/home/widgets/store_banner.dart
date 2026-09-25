import 'package:flutter/material.dart';

import '../../../core/models/store.dart';
import '../../../core/ui/ls_theme.dart';

/// Store open/closed state and address from `GET /store` (StoreBanner:
/// `surface-container-low`, bordered, `radius-md`, no banner photography).
class StoreBanner extends StatelessWidget {
  const StoreBanner({super.key, required this.store});

  final StoreInfo store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final open = store.isOpen;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OpenTag(open: open),
          if (store.address != null && store.address!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              store.address!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (!open) ...[
            const SizedBox(height: 4),
            Text(
              'You can browse; ordering resumes when the store opens.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// Open: `success` tag with a check glyph. Closed: `neutral` tag with a
/// clock glyph; ordering stays allowed.
class _OpenTag extends StatelessWidget {
  const _OpenTag({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ls = lsColorsOf(theme);
    final (bg, fg, icon, label) = open
        ? (
            ls.successContainer,
            ls.onSuccessContainer,
            Icons.check_circle_outline,
            'Open now',
          )
        : (
            ls.neutralContainer,
            ls.onNeutralContainer,
            Icons.schedule_outlined,
            'Closed',
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class StoreBannerError extends StatelessWidget {
  const StoreBannerError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          const Expanded(child: Text("Can't reach the store")),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
