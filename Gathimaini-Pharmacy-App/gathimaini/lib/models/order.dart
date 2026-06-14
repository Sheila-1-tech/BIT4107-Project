enum OrderStatus { placed, processing, outForDelivery, delivered, cancelled }

class OrderItem {
  const OrderItem({
    required this.medicineId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  final String medicineId;
  final String name;
  final double unitPrice;
  final int quantity;

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    medicineId: json['medicineId'] as String,
    name: json['name'] as String,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    quantity: (json['quantity'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'medicineId': medicineId,
    'name': name,
    'unitPrice': unitPrice,
    'quantity': quantity,
  };
}

class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.createdAt,
    this.deliveryAt,
  });

  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? deliveryAt;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    userId: json['userId'] as String,
    items: (json['items'] as List<dynamic>)
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    subtotal: (json['subtotal'] as num).toDouble(),
    deliveryFee: (json['deliveryFee'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    status: _orderStatusFromString(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    deliveryAt: json['deliveryAt'] != null
        ? DateTime.parse(json['deliveryAt'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'items': items.map((e) => e.toJson()).toList(),
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'total': total,
    'status': _orderStatusToString(status),
    'createdAt': createdAt.toIso8601String(),
    'deliveryAt': deliveryAt?.toIso8601String(),
  };

  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? total,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? deliveryAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveryAt: deliveryAt ?? this.deliveryAt,
    );
  }
}

OrderStatus _orderStatusFromString(String s) {
  switch (s) {
    case 'placed':
      return OrderStatus.placed;
    case 'processing':
      return OrderStatus.processing;
    case 'outForDelivery':
      return OrderStatus.outForDelivery;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.placed;
  }
}

String _orderStatusToString(OrderStatus status) {
  return status.toString().split('.').last;
}
