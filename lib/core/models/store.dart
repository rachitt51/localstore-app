import 'json.dart';

/// `GET /store`.
class StoreInfo {
  const StoreInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.isOpen,
    required this.codEnabled,
    required this.codMaxAmount,
    required this.minOrderAmount,
  });

  factory StoreInfo.fromJson(Json json) => StoreInfo(
    name: asString(json['name']),
    phone: asStringOrNull(json['phone']),
    address: asStringOrNull(json['address']),
    isOpen: asBool(json['isOpen'], true),
    codEnabled: asBool(json['codEnabled'], true),
    codMaxAmount: asStringOrNull(json['codMaxAmount']),
    minOrderAmount: asStringOrNull(json['minOrderAmount']),
  );

  final String name;
  final String? phone;
  final String? address;
  final bool isOpen;
  final bool codEnabled;

  /// Money string, or null when there is no cap.
  final String? codMaxAmount;
  final String? minOrderAmount;
}
