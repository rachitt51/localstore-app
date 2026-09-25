import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localstore_app/core/models/product.dart';
import 'package:localstore_app/core/ui/image_placeholder.dart';
import 'package:localstore_app/core/ui/product_card.dart';

import '../fixtures.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 200, height: 300, child: child)),
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
