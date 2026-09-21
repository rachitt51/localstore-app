import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/config/app_config.dart';

/// `GET /health` on the API; resolves to its `status` field.
final apiHealthProvider = FutureProvider.autoDispose<String>((ref) async {
  final response = await ref
      .watch(dioProvider)
      .get<Map<String, dynamic>>('/health');
  return response.data?['status'] as String? ?? 'unknown';
});

/// Placeholder landing screen until the catalog feature lands. Shows whether
/// the app can reach the API it was built against.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(apiHealthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('LocalStore')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Storefront coming soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(AppConfig.apiBaseUrl),
            const SizedBox(height: 8),
            health.when(
              data: (status) => Text('API: $status'),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => const Text('API: unreachable'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.invalidate(apiHealthProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
