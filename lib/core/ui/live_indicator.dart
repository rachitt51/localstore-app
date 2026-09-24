import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../realtime/realtime.dart';

/// Tiny dot + label for the app bar: "Live" while the realtime socket is up,
/// "Reconnecting" while one is wanted but down, nothing when signed out.
class LiveIndicator extends ConsumerWidget {
  const LiveIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(realtimeStatusProvider);
    if (status == RealtimeStatus.off) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final live = status == RealtimeStatus.connected;
    final color = live ? Colors.green.shade600 : scheme.outline;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Semantics(
        label: live ? 'Live updates on' : 'Reconnecting to live updates',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              live ? 'Live' : 'Reconnecting',
              style: text.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
