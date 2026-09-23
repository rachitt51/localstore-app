import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session.dart';
import '../features/auth/login_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/address_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/checkout/mock_payment_screen.dart';
import '../features/home/home_screen.dart';
import '../features/orders/order_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/owner/orders/owner_order_screen.dart';
import '../features/owner/orders/owner_orders_screen.dart';
import '../features/owner/products/owner_products_screen.dart';
import '../features/owner/products/product_form_screen.dart';
import '../features/product/product_screen.dart';
import 'redirect.dart';
import 'shells/customer_shell.dart';
import 'shells/owner_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Re-runs the router's redirect whenever the session changes.
class _SessionRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionRefresh();
  ref.listen(sessionProvider, (_, _) => refresh.bump());
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) =>
        redirectFor(session: ref.read(sessionProvider), uri: state.uri),
    routes: buildRoutes(),
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Detail routes are children of a tab so `go()` builds a sensible stack,
/// but render on the root navigator (no bottom bar).
List<RouteBase> buildRoutes() => [
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => CustomerShell(shell: shell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'products/:id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    ProductScreen(productId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'cart',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const CartScreen(),
              ),
              GoRoute(
                path: 'checkout',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const CheckoutScreen(),
              ),
              GoRoute(
                path: 'checkout/address',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => AddressScreen(
                  selectMode: true,
                  popOnSelect: state.uri.queryParameters['change'] == '1',
                ),
              ),
              GoRoute(
                path: 'account/addresses',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    const AddressScreen(selectMode: false),
              ),
              GoRoute(
                path: 'login',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    LoginScreen(from: state.uri.queryParameters['from']),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    OrderScreen(orderId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'pay',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        MockPaymentScreen(orderId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => OwnerShell(shell: shell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/owner',
            builder: (context, state) => const OwnerOrdersScreen(),
            routes: [
              GoRoute(
                path: 'orders/:id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    OwnerOrderScreen(orderId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/owner/products',
            builder: (context, state) => const OwnerProductsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const ProductFormScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    ProductFormScreen(productId: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
