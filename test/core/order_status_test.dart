import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localstore_app/core/models/order.dart';
import 'package:localstore_app/core/ui/order_status.dart';

void main() {
  group('OrderStatusUi', () {
    test('covers every demo status with labels, tone and icon', () {
      expect(OrderStatus.all, hasLength(9));
      for (final status in OrderStatus.all) {
        expect(OrderStatusUi.isKnown(status), isTrue, reason: status);
        final ui = OrderStatusUi.of(status);
        expect(ui.status, status);
        expect(ui.customerLabel, isNotEmpty);
        expect(ui.ownerLabel, isNotEmpty);
        expect(ui.icon, isA<IconData>());
        expect(ui.isTerminal, OrderStatus.isTerminal(status));
      }
    });

    test('customer and owner wording differ where the doc says so', () {
      expect(OrderStatusUi.of('PLACED').customerLabel, 'Order placed');
      expect(OrderStatusUi.of('PLACED').ownerLabel, 'New');
      expect(OrderStatusUi.of('IN_PROGRESS').ownerLabel, 'In progress');
      expect(OrderStatusUi.of('OUT_FOR_DELIVERY').customerLabel, 'On the way');
      expect(OrderStatusUi.of('DELIVERY_FAILED').tone, StatusTone.warning);
      expect(OrderStatusUi.of('DELIVERED').tone, StatusTone.success);
      expect(OrderStatusUi.of('REJECTED').tone, StatusTone.error);
      expect(OrderStatusUi.of('CANCELLED').tone, StatusTone.error);
      expect(OrderStatusUi.of('REFUNDED').tone, StatusTone.neutral);
      expect(OrderStatusUi.of('PENDING_PAYMENT').tone, StatusTone.neutral);
    });

    test('unknown status falls back instead of throwing', () {
      final ui = OrderStatusUi.of('SOMETHING_NEW');
      expect(OrderStatusUi.isKnown('SOMETHING_NEW'), isFalse);
      expect(ui.customerLabel, 'Something new');
      expect(ui.tone, StatusTone.neutral);
    });

    test('colours resolve for both brightnesses', () {
      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: brightness,
        );
        for (final status in OrderStatus.all) {
          final ui = OrderStatusUi.of(status);
          expect(ui.color(scheme), isA<Color>());
          expect(ui.container(scheme), isA<Color>());
          expect(ui.onContainer(scheme), isA<Color>());
        }
      }
    });
  });

  group('transitionLabel', () {
    test('human labels per (from, to)', () {
      expect(transitionLabel(from: 'PLACED', to: 'IN_PROGRESS'), 'Accept');
      expect(transitionLabel(from: 'PLACED', to: 'REJECTED'), 'Reject…');
      expect(
        transitionLabel(from: 'IN_PROGRESS', to: 'OUT_FOR_DELIVERY'),
        'Out for delivery…',
      );
      expect(
        transitionLabel(from: 'DELIVERY_FAILED', to: 'OUT_FOR_DELIVERY'),
        'Re-dispatch…',
      );
      expect(
        transitionLabel(from: 'OUT_FOR_DELIVERY', to: 'DELIVERED'),
        'Delivered',
      );
      expect(
        transitionLabel(from: 'OUT_FOR_DELIVERY', to: 'DELIVERY_FAILED'),
        'Delivery failed…',
      );
      expect(
        transitionLabel(from: 'IN_PROGRESS', to: 'CANCELLED'),
        'Cancel order…',
      );
    });
  });
}
