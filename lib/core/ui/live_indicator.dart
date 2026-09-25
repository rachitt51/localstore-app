import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../realtime/realtime.dart';
import 'ls_theme.dart';

/// Dot + label for the app bar: "Live" with a pulsing `success` dot while
/// the realtime socket is up, "Reconnecting…" with a hollow neutral dot
/// while one is wanted but down, nothing when signed out.
class LiveIndicator extends ConsumerStatefulWidget {
  const LiveIndicator({super.key});

  @override
  ConsumerState<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends ConsumerState<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(realtimeStatusProvider);
    if (status == RealtimeStatus.off) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final ls = lsColorsOf(theme);
    final live = status == RealtimeStatus.connected;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (live && !reduceMotion) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
    final color = live ? ls.success : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Semantics(
        label: live ? 'Live updates on' : 'Reconnecting to live updates',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            live
                ? FadeTransition(
                    opacity: _pulse.drive(Tween(begin: 1.0, end: 0.35)),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      border: Border.all(color: color, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                  ),
            const SizedBox(width: 6),
            Text(
              live ? 'Live' : 'Reconnecting…',
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
