import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localstore_app/app/app.dart';
import 'package:localstore_app/core/auth/session.dart';
import 'package:localstore_app/core/auth/token_store.dart';
import 'package:localstore_app/core/models/category.dart';
import 'package:localstore_app/core/models/paged.dart';
import 'package:localstore_app/core/models/product.dart';
import 'package:localstore_app/core/models/store.dart';
import 'package:localstore_app/core/ui/product_card.dart';
import 'package:localstore_app/features/home/catalog_repository.dart';

import 'fixtures.dart';

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({this.isOpen = true});

  final bool isOpen;
  String? lastQuery;

  @override
  Future<StoreInfo> store() async => StoreInfo(
    name: 'Wood Waves',
    phone: '+919999999999',
    address: 'Indiranagar, Bengaluru',
    isOpen: isOpen,
    codEnabled: true,
    codMaxAmount: '50000.00',
    minOrderAmount: '0.00',
  );

  @override
  Future<List<Category>> categories() async => const [
    Category(id: 'c1', name: 'Plywood & boards', slug: 'plywood', sortOrder: 1),
    Category(id: 'c2', name: 'Hardware', slug: 'hardware', sortOrder: 2),
  ];

  @override
  Future<Paged<ProductSummary>> products({
    String? category,
    String? q,
    bool? inStock,
    String? cursor,
    int? limit,
  }) async {
    lastQuery = q;
    return Paged(
      items: [
        ProductSummary.fromJson(productJson()),
        ProductSummary.fromJson(
          productJson(id: 'p2', inStock: false, stockQty: 0),
        ),
      ],
    );
  }

  @override
  Future<Product> product(String id) async => Product.fromJson(productJson());
}

void main() {
  testWidgets('home shows the store banner, categories and product grid', (
    tester,
  ) async {
    final catalog = FakeCatalogRepository();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalog),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).restore();
    expect(container.read(sessionProvider).isGuest, isTrue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LocalStoreApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wood Waves'), findsOneWidget);
    expect(find.text('Open now'), findsOneWidget);
    expect(find.text('Plywood & boards'), findsOneWidget);
    expect(find.text('Hardware'), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(2));
    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);

    // Search is debounced then sent as `q`.
    await tester.enterText(find.byType(TextField), 'plywood');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(catalog.lastQuery, 'plywood');
  });

  testWidgets('closed store shows the closed banner', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(isOpen: false),
          ),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        ],
        child: const LocalStoreApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Closed'), findsOneWidget);
  });
}
