import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cart_notifier.dart';

/// App-bar cart icon with the line-quantity badge.
class CartAction extends ConsumerWidget {
  const CartAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => context.push('/cart'),
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
