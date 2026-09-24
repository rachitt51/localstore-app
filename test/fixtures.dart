/// JSON fixtures shaped exactly like `demo-v0.md`.
library;

Map<String, dynamic> productJson({
  String id = 'p1',
  bool inStock = true,
  int stockQty = 12,
}) => {
  'id': id,
  'name': 'BWP Plywood 18 mm',
  'slug': 'bwp-plywood-18-mm',
  'unit': 'sheet',
  'price': '2450.00',
  'imageUrl': null,
  'inStock': inStock,
  'stockQty': stockQty,
  'autoApprove': false,
  'category': {'id': 'c1', 'name': 'Plywood & boards', 'slug': 'plywood'},
  'description': 'Boiling water proof plywood, IS:710.',
  'images': <String>[],
  'variants': [
    {
      'id': 'v1',
      'name': '8×4',
      'sku': 'BWP18-84',
      'price': '2450.00',
      'stockQty': 8,
      'isActive': true,
    },
    {
      'id': 'v2',
      'name': '7×4',
      'sku': 'BWP18-74',
      'price': '2200.00',
      'stockQty': 4,
      'isActive': true,
    },
  ],
};

Map<String, dynamic> cartJson() => {
  'items': [
    {
      'variantId': 'v1',
      'productId': 'p1',
      'name': 'BWP Plywood 18 mm',
      'variantName': '8×4',
      'unit': 'sheet',
      'imageUrl': null,
      'unitPrice': '2450.00',
      'qty': 2,
      'lineTotal': '4900.00',
      'stockQty': 8,
    },
    {
      'variantId': 'v9',
      'productId': 'p9',
      'name': 'Fevicol SH 5 kg',
      'variantName': 'Default',
      'unit': 'tin',
      'imageUrl': null,
      'unitPrice': '780.00',
      'qty': 1,
      'lineTotal': '780.00',
      'stockQty': 0,
    },
  ],
  'subtotal': '5680.00',
  'deliveryFee': '0.00',
  'total': '5680.00',
  'warnings': [
    {'variantId': 'v9', 'code': 'OUT_OF_STOCK'},
  ],
};

Map<String, dynamic> orderJson({
  String status = 'PLACED',
  bool canCancel = true,
  String? etaAt,
  int? etaMinutes,
  String paymentMethod = 'COD',
  String paymentStatus = 'PENDING',
}) => {
  'id': 'o1',
  'orderNumber': '1042',
  'status': status,
  'paymentMethod': paymentMethod,
  'paymentStatus': paymentStatus,
  'total': '4900.00',
  'itemCount': 2,
  'etaAt': etaAt,
  'createdAt': '2026-09-24T10:00:00.000Z',
  'updatedAt': '2026-09-24T10:05:00.000Z',
  'items': [
    {
      'productId': 'p1',
      'variantId': 'v1',
      'name': 'BWP Plywood 18 mm',
      'variantName': '8×4',
      'unit': 'sheet',
      'imageUrl': null,
      'unitPrice': '2450.00',
      'qty': 2,
      'lineTotal': '4900.00',
    },
  ],
  'address': {
    'label': 'Site',
    'line1': '12 MG Road',
    'line2': null,
    'landmark': 'Opp. metro',
    'pincode': '560001',
  },
  'subtotal': '4900.00',
  'deliveryFee': '0.00',
  'discount': '0.00',
  'tax': '0.00',
  'notes': 'Call on arrival',
  'etaMinutes': etaMinutes,
  'timeline': [
    {
      'status': 'PLACED',
      'note': null,
      'at': '2026-09-24T10:00:00.000Z',
      'byRole': 'CUSTOMER',
    },
    if (status != 'PLACED')
      {
        'status': status,
        'note': status == 'OUT_FOR_DELIVERY' ? 'ETA 45 min' : null,
        'at': '2026-09-24T10:05:00.000Z',
        'byRole': 'OWNER',
      },
  ],
  'canCancel': canCancel,
};

Map<String, dynamic> adminOrderJson() => {
  ...orderJson(status: 'IN_PROGRESS', canCancel: true),
  'customer': {
    'id': 'u1',
    'phone': '+919999999990',
    'name': 'Sharma Interiors',
  },
  'allowedTransitions': [
    {'to': 'OUT_FOR_DELIVERY', 'requiresNote': false, 'requiresEta': true},
    {'to': 'CANCELLED', 'requiresNote': true, 'requiresEta': false},
  ],
};
