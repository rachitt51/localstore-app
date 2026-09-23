/// Small helpers for hand-written `fromJson` constructors. The API is trusted
/// to follow `demo-v0.md`, but money and optional fields are read defensively
/// so a missing key never crashes a screen.
library;

typedef Json = Map<String, dynamic>;

Json asJson(Object? value) => (value as Map).cast<String, dynamic>();

List<Json> asJsonList(Object? value) =>
    (value as List? ?? const []).map(asJson).toList(growable: false);

String asString(Object? value, [String fallback = '']) =>
    value?.toString() ?? fallback;

String? asStringOrNull(Object? value) => value?.toString();

/// Money arrives as a 2-dp string. Numbers are tolerated but never used for
/// arithmetic on the client.
String asMoney(Object? value) {
  if (value == null) return '0.00';
  if (value is num) return value.toStringAsFixed(2);
  return value.toString();
}

int asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool asBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value == 'true';
  return fallback;
}

DateTime? asDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

List<String> asStringList(Object? value) =>
    (value as List? ?? const []).map((e) => e.toString()).toList();
