import 'package:flutter_test/flutter_test.dart';
import 'package:ems_app/core/utils/currency_formatter.dart';
import 'package:ems_app/core/utils/date_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('converts paise to formatted INR', () {
      expect(CurrencyFormatter.formatPaiseToINR(15000000), '₹1,50,000');
      expect(CurrencyFormatter.formatPaiseToINR(250000), '₹2,500');
      expect(CurrencyFormatter.formatPaiseToINR(499900), '₹4,999');
      expect(CurrencyFormatter.formatPaiseToINR(0), '₹0');
    });

    test('parses INR back to paise', () {
      expect(CurrencyFormatter.parseINRToPaise('₹1,50,000'), 15000000);
      expect(CurrencyFormatter.parseINRToPaise('2,500'), 250000);
    });
  });

  group('DateFormatter Tests', () {
    test('calculates SLA countdown correctly', () {
      final in18Hours = DateTime.now().add(const Duration(hours: 18));
      expect(DateFormatter.formatSlaRemaining(in18Hours).contains('remaining'), true);

      final expired = DateTime.now().subtract(const Duration(hours: 1));
      expect(DateFormatter.formatSlaRemaining(expired), 'SLA Expired');
    });
  });
}
