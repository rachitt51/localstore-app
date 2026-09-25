import 'package:flutter_test/flutter_test.dart';
import 'package:localstore_app/core/ui/format.dart';

void main() {
  group('formatInr', () {
    test('adds the rupee sign and keeps the decimals as sent', () {
      expect(formatInr('0.00'), '₹0.00');
      expect(formatInr('5'), '₹5');
      expect(formatInr('999.50'), '₹999.50');
      expect(formatInr('2450.00'), '₹2,450.00');
    });

    test('uses Indian grouping (2-digit groups above the thousands)', () {
      expect(formatInr('12345.00'), '₹12,345.00');
      expect(formatInr('123456.00'), '₹1,23,456.00');
      expect(formatInr('1234567.50'), '₹12,34,567.50');
      expect(formatInr('100000000'), '₹10,00,00,000');
    });

    test('negative amounts and odd input do not crash', () {
      expect(formatInr('-1250.00'), '−₹1,250.00');
      expect(formatInr(''), '₹0');
      expect(formatInr('abc'), '₹abc');
    });
  });

  group('compareMoney', () {
    test('compares decimal strings without floating point', () {
      expect(compareMoney('100.00', '100.00'), 0);
      expect(compareMoney('100.00', '100'), 0);
      expect(compareMoney('99.99', '100.00'), lessThan(0));
      expect(compareMoney('5000.01', '5000.00'), greaterThan(0));
      expect(compareMoney('10000.00', '9999.99'), greaterThan(0));
      expect(compareMoney('0999.00', '999.00'), 0);
    });
  });

  group('formatEtaRemaining', () {
    final now = DateTime(2026, 9, 24, 18, 0);
    test('minutes and hours', () {
      expect(
        formatEtaRemaining(now.add(const Duration(minutes: 45)), now: now),
        'in 45 min',
      );
      expect(
        formatEtaRemaining(now.add(const Duration(minutes: 125)), now: now),
        'in 2 h 5 min',
      );
    });
    test('overdue', () {
      expect(
        formatEtaRemaining(now.subtract(const Duration(minutes: 3)), now: now),
        'overdue by 3 min',
      );
    });
  });
}
