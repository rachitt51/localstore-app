import 'json.dart';

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.line1,
    this.line2,
    this.landmark,
    required this.pincode,
    required this.isDefault,
  });

  factory Address.fromJson(Json json) => Address(
    id: asString(json['id']),
    label: asString(json['label']),
    line1: asString(json['line1']),
    line2: asStringOrNull(json['line2']),
    landmark: asStringOrNull(json['landmark']),
    pincode: asString(json['pincode']),
    isDefault: asBool(json['isDefault']),
  );

  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String? landmark;
  final String pincode;
  final bool isDefault;

  /// One-line rendering for summaries.
  String get oneLine => [
    line1,
    if (line2 != null && line2!.isNotEmpty) line2,
    if (landmark != null && landmark!.isNotEmpty) landmark,
    pincode,
  ].join(', ');
}

/// The address snapshot on an order (no id, no default flag).
class OrderAddress {
  const OrderAddress({
    required this.label,
    required this.line1,
    this.line2,
    this.landmark,
    required this.pincode,
  });

  factory OrderAddress.fromJson(Json json) => OrderAddress(
    label: asString(json['label']),
    line1: asString(json['line1']),
    line2: asStringOrNull(json['line2']),
    landmark: asStringOrNull(json['landmark']),
    pincode: asString(json['pincode']),
  );

  final String label;
  final String line1;
  final String? line2;
  final String? landmark;
  final String pincode;

  String get oneLine => [
    line1,
    if (line2 != null && line2!.isNotEmpty) line2,
    if (landmark != null && landmark!.isNotEmpty) landmark,
    pincode,
  ].join(', ');
}
