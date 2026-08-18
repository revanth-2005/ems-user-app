import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Converts an amount in Paise (e.g. 15000000) to formatted INR (e.g. "₹1,50,000")
  static String formatPaiseToINR(int paise, {bool includeSymbol = true}) {
    final double rupees = paise / 100.0;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: includeSymbol ? '₹' : '',
      decimalDigits: rupees % 1 == 0 ? 0 : 2,
    );
    return formatter.format(rupees).trim();
  }

  static String formatPaise(int paise, {bool includeSymbol = true}) =>
      formatPaiseToINR(paise, includeSymbol: includeSymbol);

  /// Parses INR string back to Paise
  static int parseINRToPaise(String inrText) {
    final clean = inrText.replaceAll(RegExp(r'[^0-9.]'), '');
    final double val = double.tryParse(clean) ?? 0.0;
    return (val * 100).round();
  }
}
