import 'package:intl/intl.dart';

/// Formats an API money string (`"1234567.50"`) as `₹12,34,567.50` with
/// Indian digit grouping and a true minus (U+2212) for deductions. The
/// string is never parsed to a number: the digits are regrouped as text so
/// the value shown is exactly what the API sent.
String formatInr(String amount) {
  var s = amount.trim();
  if (s.isEmpty) return '₹0';
  var sign = '';
  if (s.startsWith('-')) {
    sign = '−';
    s = s.substring(1);
  }
  final dot = s.indexOf('.');
  final intPart = dot == -1 ? s : s.substring(0, dot);
  final fraction = dot == -1 ? '' : s.substring(dot);
  if (intPart.isEmpty || !RegExp(r'^\d+$').hasMatch(intPart)) {
    return '$sign₹$s';
  }
  return '$sign₹${_groupIndian(intPart)}$fraction';
}

String _groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}

/// Compares two non-negative decimal money strings without floating point.
/// Returns a negative number if `a < b`, zero if equal, positive if `a > b`.
int compareMoney(String a, String b) {
  final pa = _splitMoney(a);
  final pb = _splitMoney(b);
  if (pa.$1.length != pb.$1.length) return pa.$1.length - pb.$1.length;
  final intCmp = pa.$1.compareTo(pb.$1);
  if (intCmp != 0) return intCmp;
  final width = pa.$2.length > pb.$2.length ? pa.$2.length : pb.$2.length;
  return pa.$2.padRight(width, '0').compareTo(pb.$2.padRight(width, '0'));
}

(String, String) _splitMoney(String s) {
  final t = s.trim();
  final dot = t.indexOf('.');
  var intPart = dot == -1 ? t : t.substring(0, dot);
  final frac = dot == -1 ? '' : t.substring(dot + 1);
  intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  return (intPart.isEmpty ? '0' : intPart, frac);
}

final _dateTimeFormat = DateFormat('d MMM, h:mm a');
final _timeFormat = DateFormat('h:mm a');

String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt.toLocal());
String formatTime(DateTime dt) => _timeFormat.format(dt.toLocal());

/// "in 42 min", "in 1 h 5 min", or "overdue by 3 min".
String formatEtaRemaining(DateTime etaAt, {DateTime? now}) {
  final diff = etaAt.difference(now ?? DateTime.now());
  final overdue = diff.isNegative;
  final minutes = diff.abs().inMinutes;
  final text = minutes >= 60
      ? '${minutes ~/ 60} h ${minutes % 60} min'
      : '$minutes min';
  return overdue ? 'overdue by $text' : 'in $text';
}
