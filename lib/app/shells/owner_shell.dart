import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/ls_theme.dart';
import '../../features/owner/orders/owner_orders_notifier.dart';

/// Owner mode: graphite app bar with the OWNER tag, bottom nav Orders
/// (badged with the New count) / Products. Wraps [shell] in the design
/// system's owner-mode `Theme` override: compact density and
/// `secondaryContainer` selection, never the storefront's primary teal.
class OwnerShell extends ConsumerWidget {
  const OwnerShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ls = lsColorsOf(theme);
    final newCount = ref.watch(ownerSummaryProvider).value?.newCount ?? 0;
    return Theme(
      data: theme.copyWith(
        visualDensity: VisualDensity.compact,
        navigationBarTheme: theme.navigationBarTheme.copyWith(
          indicatorColor: scheme.secondaryContainer,
        ),
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: ls.ownerBar,
          foregroundColor: ls.onOwnerBar,
          shape: const Border(),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OwnerTag(ls: ls, theme: theme),
              const SizedBox(width: 8),
              Text(switch (shell.currentIndex) {
                0 => 'Orders',
                1 => 'Products',
                _ => 'Visits',
              }),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => context.go('/'),
              style: TextButton.styleFrom(foregroundColor: ls.onOwnerBar),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Back to store'),
            ),
          ],
        ),
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            NavigationDestination(
              icon: _NavIcon(icon: Icons.inbox_outlined, badge: newCount),
              selectedIcon: _NavIcon(icon: Icons.inbox, badge: newCount),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            const NavigationDestination(
              icon: Icon(Icons.event_available_outlined),
              selectedIcon: Icon(Icons.event_available),
              label: 'Visits',
            ),
          ],
        ),
      ),
    );
  }
}

/// Small `ownerAccent` tag before the AppBar title: the owner-mode cue is
/// structural and always present, per the design system's owner-mode rule.
class _OwnerTag extends StatelessWidget {
  const _OwnerTag({required this.ls, required this.theme});

  final LsColors ls;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ls.ownerAccent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'OWNER',
        style: theme.textTheme.labelSmall?.copyWith(color: ls.onOwnerAccent),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.badge});

  final IconData icon;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final child = Icon(icon);
    if (badge <= 0) return child;
    return Badge(label: Text('$badge'), child: child);
  }
}
