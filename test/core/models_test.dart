import 'package:flutter_test/flutter_test.dart';
import 'package:localstore_app/core/models/cart.dart';
import 'package:localstore_app/core/models/order.dart';
import 'package:localstore_app/core/models/paged.dart';
import 'package:localstore_app/core/models/product.dart';

import '../fixtures.dart';

void main() {
  group('Product.fromJson', () {
    test('reads summary fields, category, description and variants', () {
      final p = Product.fromJson(productJson());
      expect(p.id, 'p1');
      expect(p.name, 'BWP Plywood 18 mm');
      expect(p.unit, 'sheet');
      expect(p.price, '2450.00');
      expect(p.imageUrl, isNull);
      expect(p.inStock, isTrue);
      expect(p.stockQty, 12);
      expect(p.category.slug, 'plywood');
      expect(p.description, contains('IS:710'));
      expect(p.images, isEmpty);
      expect(p.variants, hasLength(2));
      expect(p.variants[1].price, '2200.00');
      expect(p.variants[1].sku, 'BWP18-74');
      expect(p.activeVariants, hasLength(2));
    });

    test('keeps money as the API string and tolerates numbers', () {
      final json = productJson()..['price'] = 2450;
      expect(ProductSummary.fromJson(json).price, '2450.00');
    });

    test('admin product adds basePrice, isActive, categoryId', () {
      final json = productJson()
        ..['basePrice'] = '2450.00'
        ..['isActive'] = false
        ..['sortOrder'] = 3
        ..['categoryId'] = 'c1';
      json['variants'][0]['priceDelta'] = '0.00';
      final p = AdminProduct.fromJson(json);
      expect(p.basePrice, '2450.00');
      expect(p.isActive, isFalse);
      expect(p.sortOrder, 3);
      expect(p.categoryId, 'c1');
      expect(p.variants.first.priceDelta, '0.00');
    });

    test('paged list parses items and cursor', () {
      final page = Paged.fromJson({
        'items': [productJson(), productJson(id: 'p2')],
        'nextCursor': 'abc',
      }, ProductSummary.fromJson);
      expect(page.items.map((p) => p.id), ['p1', 'p2']);
      expect(page.hasMore, isTrue);
      final more = page.append(
        Paged.fromJson({
          'items': [productJson(id: 'p3')],
          'nextCursor': null,
        }, ProductSummary.fromJson),
      );
      expect(more.items, hasLength(3));
      expect(more.hasMore, isFalse);
    });
  });

  group('Cart.fromJson', () {
    test('reads lines, totals and warnings', () {
      final cart = Cart.fromJson(cartJson());
      expect(cart.items, hasLength(2));
      expect(cart.items.first.lineTotal, '4900.00');
      expect(cart.subtotal, '5680.00');
      expect(cart.deliveryFee, '0.00');
      expect(cart.total, '5680.00');
      expect(cart.itemCount, 3);
      expect(cart.warnings.single.code, 'OUT_OF_STOCK');
      expect(cart.warningFor('v9')?.message, 'Out of stock');
      expect(cart.warningFor('v1'), isNull);
      expect(cart.hasBlockingWarnings, isTrue);
    });

    test('empty cart', () {
      final cart = Cart.fromJson({
        'items': [],
        'subtotal': '0.00',
        'deliveryFee': '0.00',
        'total': '0.00',
        'warnings': [],
      });
      expect(cart.isEmpty, isTrue);
      expect(cart.hasBlockingWarnings, isFalse);
    });

    test('warning messages', () {
      expect(
        const CartWarning(
          variantId: 'v',
          code: 'INSUFFICIENT_STOCK',
          available: 3,
        ).message,
        'Only 3 available',
      );
      expect(
        const CartWarning(variantId: 'v', code: 'PRICE_CHANGED').message,
        'Price has changed',
      );
    });
  });

  group('Order.fromJson', () {
    test('reads summary, lines, address, timeline and canCancel', () {
      final o = Order.fromJson(orderJson());
      expect(o.orderNumber, '1042');
      expect(o.status, OrderStatus.placed);
      expect(o.paymentMethod, 'COD');
      expect(o.total, '4900.00');
      expect(o.itemCount, 2);
      expect(o.etaAt, isNull);
      expect(o.items.single.qty, 2);
      expect(o.address?.pincode, '560001');
      expect(o.address?.oneLine, '12 MG Road, Opp. metro, 560001');
      expect(o.notes, 'Call on arrival');
      expect(o.timeline, hasLength(1));
      expect(o.timeline.first.status, 'PLACED');
      expect(o.timeline.first.byRole, 'CUSTOMER');
      expect(o.timeline.first.at.toUtc().hour, 10);
      expect(o.canCancel, isTrue);
      expect(o.isTerminal, isFalse);
    });

    test('out for delivery carries etaAt and a two-step timeline', () {
      final o = Order.fromJson(
        orderJson(
          status: OrderStatus.outForDelivery,
          canCancel: false,
          etaAt: '2026-09-24T10:50:00.000Z',
          etaMinutes: 45,
        ),
      );
      expect(o.etaAt, isNotNull);
      expect(o.etaMinutes, 45);
      expect(o.timeline, hasLength(2));
      expect(o.timeline.last.note, 'ETA 45 min');
      expect(o.canCancel, isFalse);
    });

    test('terminal statuses', () {
      for (final s in [
        OrderStatus.delivered,
        OrderStatus.rejected,
        OrderStatus.cancelled,
        OrderStatus.refunded,
      ]) {
        expect(Order.fromJson(orderJson(status: s)).isTerminal, isTrue);
      }
      expect(
        Order.fromJson(orderJson(status: OrderStatus.deliveryFailed))
            .isTerminal,
        isFalse,
      );
    });

    test('admin order adds customer and allowedTransitions', () {
      final o = AdminOrder.fromJson(adminOrderJson());
      expect(o.customer.displayName, 'Sharma Interiors');
      expect(o.allowedTransitions, hasLength(2));
      expect(o.allowedTransitions.first.to, OrderStatus.outForDelivery);
      expect(o.allowedTransitions.first.requiresEta, isTrue);
      expect(o.allowedTransitions.last.requiresNote, isTrue);
    });

    test('summary list item', () {
      final s = OrderSummary.fromJson({
        'id': 'o2',
        'orderNumber': '1043',
        'status': 'DELIVERED',
        'paymentMethod': 'UPI',
        'paymentStatus': 'PAID',
        'total': '780.00',
        'itemCount': 1,
        'etaAt': null,
        'createdAt': '2026-09-24T09:00:00.000Z',
        'updatedAt': '2026-09-24T11:00:00.000Z',
      });
      expect(s.isTerminal, isTrue);
      expect(s.total, '780.00');
    });
  });
}
