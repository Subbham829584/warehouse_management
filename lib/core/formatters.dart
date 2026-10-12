import 'package:intl/intl.dart';
import 'package:warehouse_management/core/constants.dart';

class Fmt {
  Fmt._();

  static final NumberFormat _money = NumberFormat.currency(
      locale: 'en_IN', symbol: AppConstants.currency, decimalDigits: 2);
  static final NumberFormat _compact = NumberFormat.compactCurrency(
      locale: 'en_IN', symbol: AppConstants.currency);
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static String money(num? v) => _money.format(v ?? 0);
  static String moneyCompact(num? v) => _compact.format(v ?? 0);
  static String dateTime(DateTime? d) => d == null ? '-' : _dateTime.format(d);
}
