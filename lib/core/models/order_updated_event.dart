import 'json.dart';

/// The `order.updated` Socket.IO event (`demo-v0.md`, Realtime). A signal
/// only: consumers re-fetch the order or list they are showing.
class OrderUpdatedEvent {
  const OrderUpdatedEvent({
    required this.orderId,
    required this.orderNumber,
    required this.userId,
    required this.status,
    required this.paymentStatus,
    this.etaAt,
    required this.updatedAt,
    required this.reason,
  });

  factory OrderUpdatedEvent.fromJson(Json json) => OrderUpdatedEvent(
    orderId: asString(json['orderId']),
    orderNumber: asString(json['orderNumber']),
    userId: asString(json['userId']),
    status: asString(json['status']),
    paymentStatus: asString(json['paymentStatus']),
    etaAt: asDateTime(json['etaAt']),
    updatedAt: asDateTime(json['updatedAt']) ?? DateTime.now(),
    reason: asString(json['reason']),
  );

  final String orderId;
  final String orderNumber;
  final String userId;
  final String status;
  final String paymentStatus;
  final DateTime? etaAt;
  final DateTime updatedAt;

  /// `created | transitioned`.
  final String reason;

  bool get isCreated => reason == 'created';

  @override
  String toString() =>
      'OrderUpdatedEvent(#$orderNumber $status/$paymentStatus, $reason)';
}
