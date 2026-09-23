import 'package:flutter/material.dart';

import '../../../core/models/store.dart';

/// Store name/address with the open/closed state from `GET /store`.
class StoreBanner extends StatelessWidget {
  const StoreBanner({super.key, required this.store});

  final StoreInfo store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final closed = !store.isOpen;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: closed ? scheme.errorContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            closed ? Icons.storefront_outlined : Icons.storefront,
            color: closed ? scheme.onErrorContainer : scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  closed ? 'Store closed' : 'Open for orders',
                  style: text.titleSmall?.copyWith(
                    color: closed
                        ? scheme.onErrorContainer
                        : scheme.onPrimaryContainer,
                  ),
                ),
                if (store.address != null && store.address!.isNotEmpty)
                  Text(
                    store.address!,
                    style: text.bodySmall?.copyWith(
                      color: closed
                          ? scheme.onErrorContainer
                          : scheme.onPrimaryContainer,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (closed)
                  Text(
                    'You can browse; ordering resumes when the store opens.',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
              ],
            ),
          ),
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
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
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
