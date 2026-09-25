import 'package:flutter/material.dart';

import '../api/api_exception.dart';

/// Full-area failure with a retry button. Network errors get their own
/// wording; API errors show the API's message.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final network = isNetworkError(error);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                network ? Icons.wifi_off : Icons.error_outline,
                size: 28,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              network ? "Can't reach the store" : 'Something went wrong',
              style: text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage(error),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error line placed next to the action that failed.
class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: scheme.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
