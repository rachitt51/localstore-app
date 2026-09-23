import 'address.dart';
import 'json.dart';
import 'user.dart';

/// Order statuses from `demo-v0.md`.
abstract final class OrderStatus {
  static const pendingPayment = 'PENDING_PAYMENT';
  static const placed = 'PLACED';
  static const inProgress = 'IN_PROGRESS';
  static const outForDelivery = 'OUT_FOR_DELIVERY';
  static const delivered = 'DELIVERED';
  static const deliveryFailed = 'DELIVERY_FAILED';
  static const rejected = 'REJECTED';
  static const cancelled = 'CANCELLED';
  static const refunded = 'REFUNDED';

  static const all = [
    pendingPayment,
    placed,
    inProgress,
    outForDelivery,
    delivered,
    deliveryFailed,
    rejected,
    cancelled,
    refunded,
  ];

  static const terminal = {delivered, rejected, cancelled, refunded};

  static bool isTerminal(String status) => terminal.contains(status);
}

abstract final class PaymentMethod {
  static const cod = 'COD';
  static const upi = 'UPI';
  static const card = 'CARD';
  static const netbanking = 'NETBANKING';

  static const online = [upi, card, netbanking];

  static bool isOnline(String method) => method != cod;

  static String label(String method) => switch (method) {
    cod => 'Cash on delivery',
    upi => 'UPI',
    card => 'Card',
    netbanking => 'Net banking',
    _ => method,
  };
}

abstract final class PaymentStatus {
  static String label(String status) => switch (status) {
    'PENDING' => 'Pending',
    'PAID' => 'Paid',
    'FAILED' => 'Failed',
    'REFUNDED' => 'Refunded',
    _ => status,
  };
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.total,
    required this.itemCount,
    this.etaAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderSummary.fromJson(Json json) => OrderSummary(
    id: asString(json['id']),
    orderNumber: asString(json['orderNumber']),
    status: asString(json['status']),
    paymentMethod: asString(json['paymentMethod']),
    paymentStatus: asString(json['paymentStatus']),
    total: asMoney(json['total']),
    itemCount: asInt(json['itemCount']),
    etaAt: asDateTime(json['etaAt']),
    createdAt: asDateTime(json['createdAt']) ?? DateTime.now(),
    updatedAt: asDateTime(json['updatedAt']) ?? DateTime.now(),
  );

  final String id;
  final String orderNumber;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String total;
  final int itemCount;
  final DateTime? etaAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal => OrderStatus.isTerminal(status);
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.variantId,
    required this.name,
    this.variantName,
    required this.unit,
    this.imageUrl,
    required this.unitPrice,
    required this.qty,
    required this.lineTotal,
  });

  factory OrderLine.fromJson(Json json) => OrderLine(
    productId: asString(json['productId']),
    variantId: asString(json['variantId']),
    name: asString(json['name']),
    variantName: asStringOrNull(json['variantName']),
    unit: asString(json['unit']),
    imageUrl: asStringOrNull(json['imageUrl']),
    unitPrice: asMoney(json['unitPrice']),
    qty: asInt(json['qty']),
    lineTotal: asMoney(json['lineTotal']),
  );

  final String productId;
  final String variantId;
  final String name;
  final String? variantName;
  final String unit;
  final String? imageUrl;
  final String unitPrice;
  final int qty;
  final String lineTotal;
}

class OrderEvent {
  const OrderEvent({
    required this.status,
    this.note,
    required this.at,
    required this.byRole,
  });

  factory OrderEvent.fromJson(Json json) => OrderEvent(
    status: asString(json['status']),
    note: asStringOrNull(json['note']),
    at: asDateTime(json['at']) ?? DateTime.now(),
    byRole: asString(json['byRole'], 'SYSTEM'),
  );

  final String status;
  final String? note;
  final DateTime at;

  /// `CUSTOMER | OWNER | STAFF | SYSTEM`.
  final String byRole;
}

class Order extends OrderSummary {
  const Order({
    required super.id,
    required super.orderNumber,
    required super.status,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.total,
    required super.itemCount,
    super.etaAt,
    required super.createdAt,
    required super.updatedAt,
    required this.items,
    required this.address,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.tax,
    this.notes,
    this.etaMinutes,
    required this.timeline,
    required this.canCancel,
  });

  factory Order.fromJson(Json json) {
    final s = OrderSummary.fromJson(json);
    return Order(
      id: s.id,
      orderNumber: s.orderNumber,
      status: s.status,
      paymentMethod: s.paymentMethod,
      paymentStatus: s.paymentStatus,
      total: s.total,
      itemCount: s.itemCount,
      etaAt: s.etaAt,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      items: asJsonList(json['items'])
          .map(OrderLine.fromJson)
          .toList(growable: false),
      address: json['address'] == null
          ? null
          : OrderAddress.fromJson(asJson(json['address'])),
      subtotal: asMoney(json['subtotal']),
      deliveryFee: asMoney(json['deliveryFee']),
      discount: asMoney(json['discount']),
      tax: asMoney(json['tax']),
      notes: asStringOrNull(json['notes']),
      etaMinutes: json['etaMinutes'] == null ? null : asInt(json['etaMinutes']),
      timeline: asJsonList(json['timeline'])
          .map(OrderEvent.fromJson)
          .toList(growable: false),
      canCancel: asBool(json['canCancel']),
    );
  }

  final List<OrderLine> items;
  final OrderAddress? address;
  final String subtotal;
  final String deliveryFee;
  final String discount;
  final String tax;
  final String? notes;
  final int? etaMinutes;
  final List<OrderEvent> timeline;
  final bool canCancel;
}

/// One entry of an admin order's `allowedTransitions`.
class AllowedTransition {
  const AllowedTransition({
    required this.to,
    required this.requiresNote,
    required this.requiresEta,
  });

  factory AllowedTransition.fromJson(Json json) => AllowedTransition(
    to: asString(json['to']),
    requiresNote: asBool(json['requiresNote']),
    requiresEta: asBool(json['requiresEta']),
  );

  final String to;
  final bool requiresNote;
  final bool requiresEta;
}

/// `{id, phone, name}` on admin order responses.
class CustomerRef {
  const CustomerRef({required this.id, required this.phone, this.name});

  factory CustomerRef.fromJson(Json json) => CustomerRef(
    id: asString(json['id']),
    phone: asString(json['phone']),
    name: asStringOrNull(json['name']),
  );

  final String id;
  final String phone;
  final String? name;

  String get displayName =>
      (name == null || name!.trim().isEmpty) ? phone : name!;

  User toUser() => User(id: id, phone: phone, name: name, role: 'CUSTOMER');
}

class AdminOrderSummary extends OrderSummary {
  const AdminOrderSummary({
    required super.id,
    required super.orderNumber,
    required super.status,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.total,
    required super.itemCount,
    super.etaAt,
    required super.createdAt,
    required super.updatedAt,
    required this.customer,
  });

  factory AdminOrderSummary.fromJson(Json json) {
    final s = OrderSummary.fromJson(json);
    return AdminOrderSummary(
      id: s.id,
      orderNumber: s.orderNumber,
      status: s.status,
      paymentMethod: s.paymentMethod,
      paymentStatus: s.paymentStatus,
      total: s.total,
      itemCount: s.itemCount,
      etaAt: s.etaAt,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      customer: CustomerRef.fromJson(asJson(json['customer'])),
    );
  }

  final CustomerRef customer;
}

class AdminOrder extends Order {
  const AdminOrder({
    required super.id,
    required super.orderNumber,
    required super.status,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.total,
    required super.itemCount,
    super.etaAt,
    required super.createdAt,
    required super.updatedAt,
    required super.items,
    required super.address,
    required super.subtotal,
    required super.deliveryFee,
    required super.discount,
    required super.tax,
    super.notes,
    super.etaMinutes,
    required super.timeline,
    required super.canCancel,
    required this.customer,
    required this.allowedTransitions,
  });

  factory AdminOrder.fromJson(Json json) {
    final o = Order.fromJson(json);
    return AdminOrder(
      id: o.id,
      orderNumber: o.orderNumber,
      status: o.status,
      paymentMethod: o.paymentMethod,
      paymentStatus: o.paymentStatus,
      total: o.total,
      itemCount: o.itemCount,
      etaAt: o.etaAt,
      createdAt: o.createdAt,
      updatedAt: o.updatedAt,
      items: o.items,
      address: o.address,
      subtotal: o.subtotal,
      deliveryFee: o.deliveryFee,
      discount: o.discount,
      tax: o.tax,
      notes: o.notes,
      etaMinutes: o.etaMinutes,
      timeline: o.timeline,
      canCancel: o.canCancel,
      customer: CustomerRef.fromJson(asJson(json['customer'])),
      allowedTransitions: asJsonList(json['allowedTransitions'])
          .map(AllowedTransition.fromJson)
          .toList(growable: false),
    );
  }

  final CustomerRef customer;
  final List<AllowedTransition> allowedTransitions;
}

/// `GET /admin/orders/summary`.
class OrdersSummary {
  const OrdersSummary({
    required this.newCount,
    required this.inProgressCount,
    required this.outForDeliveryCount,
    required this.todayDelivered,
    required this.todayRevenue,
  });

  factory OrdersSummary.fromJson(Json json) => OrdersSummary(
    newCount: asInt(json['newCount']),
    inProgressCount: asInt(json['inProgressCount']),
    outForDeliveryCount: asInt(json['outForDeliveryCount']),
    todayDelivered: asInt(json['todayDelivered']),
    todayRevenue: asMoney(json['todayRevenue']),
  );

  final int newCount;
  final int inProgressCount;
  final int outForDeliveryCount;
  final int todayDelivered;
  final String todayRevenue;
}
