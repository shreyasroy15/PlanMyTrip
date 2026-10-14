import 'package:intl/intl.dart';

class Formatters {
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('hh:mm a').format(date);
  }

  static String formatCurrency(num amount, {String symbol = '\$'}) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 0).format(amount);
  }
}
