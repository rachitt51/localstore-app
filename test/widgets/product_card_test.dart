import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localstore_app/core/models/product.dart';
import 'package:localstore_app/core/ui/image_placeholder.dart';
import 'package:localstore_app/core/ui/product_card.dart';

import '../fixtures.dart';

// Tall enough that the quick-add button's cart-quantity Badge (see
// product_card.dart) never overflows the card's info column.
Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 200, height: 320, child: child)),
  ),
);

void main() {
  testWidgets('renders name, formatted price, unit and stock', (tester) async {
    final product = ProductSummary.fromJson(productJson());
    var tapped = false;
    await tester.pumpWidget(
      _wrap(ProductCard(product: product, onTap: () => tapped = true)),
    );

    expect(find.text('BWP Plywood 18 mm'), findsOneWidget);
    expect(find.textContaining('₹2,450.00'), findsOneWidget);
    expect(find.textContaining('/ sheet'), findsOneWidget);
    expect(find.text('12 sheets in stock'), findsOneWidget);
    expect(find.text('Out of stock'), findsNothing);
    // No imageUrl → placeholder, no network image.
    expect(find.byType(ImagePlaceholder), findsOneWidget);

    await tester.tap(find.byType(ProductCard));
    expect(tapped, isTrue);
  });

  testWidgets('in cart: shows the −/count/+ stepper with the quantity', (
    tester,
  ) async {
    final product = ProductSummary.fromJson(productJson());
    var added = false;
    var removed = false;
    await tester.pumpWidget(
      _wrap(
        ProductCard(
          product: product,
          onQuickAdd: () => added = true,
          onQuickRemove: () => removed = true,
          cartQty: 3,
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    // The stepper replaces the plain add button and the stock line.
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.textContaining('in stock'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.remove));
    expect(added, isTrue);
    expect(removed, isTrue);
  });

  testWidgets('not in cart: shows the plain add button and stock', (
    tester,
  ) async {
    final product = ProductSummary.fromJson(productJson());
    await tester.pumpWidget(
      _wrap(ProductCard(product: product, onQuickAdd: () {})),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsNothing);
    expect(find.text('12 sheets in stock'), findsOneWidget);
  });

  testWidgets('shows the out-of-stock badge', (tester) async {
    final product = ProductSummary.fromJson(
      productJson(inStock: false, stockQty: 0),
    );
    await tester.pumpWidget(_wrap(ProductCard(product: product)));

    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.textContaining('in stock'), findsNothing);
    expect(find.textContaining('₹2,450.00'), findsOneWidget);
  });
}
