import 'json.dart';

/// Home-visit request statuses.
abstract final class VisitStatus {
  static const requested = 'REQUESTED';
  static const confirmed = 'CONFIRMED';
  static const declined = 'DECLINED';
  static const cancelled = 'CANCELLED';
}

/// A minimal customer reference on the admin view of a visit.
class VisitCustomer {
  const VisitCustomer({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory VisitCustomer.fromJson(Json json) => VisitCustomer(
    id: asString(json['id']),
    name: asStringOrNull(json['name']),
    phone: asString(json['phone']),
  );

  final String id;
  final String? name;
  final String phone;

  String get displayName =>
      (name == null || name!.trim().isEmpty) ? phone : name!;
}

/// `POST /visits`, `GET /visits` item.
class VisitDto {
  const VisitDto({
    required this.id,
    required this.status,
    required this.preferredAt,
    this.note,
    this.ownerNote,
    required this.createdAt,
    this.customer,
  });

  factory VisitDto.fromJson(Json json) => VisitDto(
    id: asString(json['id']),
    status: asString(json['status'], VisitStatus.requested),
    preferredAt: asDateTime(json['preferredAt']) ?? DateTime.now(),
    note: asStringOrNull(json['note']),
    ownerNote: asStringOrNull(json['ownerNote']),
    createdAt: asDateTime(json['createdAt']) ?? DateTime.now(),
    customer: json['customer'] == null
        ? null
        : VisitCustomer.fromJson(asJson(json['customer'])),
  );

  final String id;
  final String status;
  final DateTime preferredAt;
  final String? note;
  final String? ownerNote;
  final DateTime createdAt;

  /// Present only on admin responses.
  final VisitCustomer? customer;

  bool get isCancellable => status == VisitStatus.requested;
}
