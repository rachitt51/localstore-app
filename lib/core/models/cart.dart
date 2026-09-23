import 'json.dart';

class CartLine {
  const CartLine({
    required this.variantId,
    required this.productId,
    required this.name,
    this.variantName,
    required this.unit,
    this.imageUrl,
    required this.unitPrice,
    required this.qty,
    required this.lineTotal,
    required this.stockQty,
  });

  factory CartLine.fromJson(Json json) => CartLine(
    variantId: asString(json['variantId']),
    productId: asString(json['productId']),
    name: asString(json['name']),
    variantName: asStringOrNull(json['variantName']),
    unit: asString(json['unit']),
    imageUrl: asStringOrNull(json['imageUrl']),
    unitPrice: asMoney(json['unitPrice']),
    qty: asInt(json['qty']),
    lineTotal: asMoney(json['lineTotal']),
    stockQty: asInt(json['stockQty']),
  );

  final String variantId;
  final String productId;
  final String name;
  final String? variantName;
  final String unit;
  final String? imageUrl;
  final String unitPrice;
  final int qty;
  final String lineTotal;
  final int stockQty;
}

class CartWarning {
  const CartWarning({
    required this.variantId,
    required this.code,
    this.available,
  });

  factory CartWarning.fromJson(Json json) => CartWarning(
    variantId: asString(json['variantId']),
    code: asString(json['code']),
    available: json['available'] == null ? null : asInt(json['available']),
  );

  final String variantId;

  /// `OUT_OF_STOCK | INSUFFICIENT_STOCK | PRICE_CHANGED`.
  final String code;
  final int? available;

  String get message => switch (code) {
    'OUT_OF_STOCK' => 'Out of stock',
    'INSUFFICIENT_STOCK' =>
      available == null ? 'Not enough stock' : 'Only $available available',
    'PRICE_CHANGED' => 'Price has changed',
    _ => code,
  };
}

class Cart {
  const Cart({
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.warnings,
  });

  factory Cart.fromJson(Json json) => Cart(
    items: asJsonList(json['items'])
        .map(CartLine.fromJson)
        .toList(growable: false),
    subtotal: asMoney(json['subtotal']),
    deliveryFee: asMoney(json['deliveryFee']),
    total: asMoney(json['total']),
    warnings: asJsonList(json['warnings'])
        .map(CartWarning.fromJson)
        .toList(growable: false),
  );

  static const empty = Cart(
    items: [],
    subtotal: '0.00',
    deliveryFee: '0.00',
    total: '0.00',
    warnings: [],
  );

  final List<CartLine> items;
  final String subtotal;
  final String deliveryFee;
  final String total;
  final List<CartWarning> warnings;

  bool get isEmpty => items.isEmpty;

  /// Sum of quantities, for the app-bar badge.
  int get itemCount => items.fold(0, (sum, line) => sum + line.qty);

  CartWarning? warningFor(String variantId) {
    for (final w in warnings) {
      if (w.variantId == variantId) return w;
    }
    return null;
  }

  bool get hasBlockingWarnings => warnings.any(
    (w) => w.code == 'OUT_OF_STOCK' || w.code == 'INSUFFICIENT_STOCK',
  );
}
