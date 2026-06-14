class SqliteMedicine {
  final int? id;
  final String medicineName;
  final String category;
  final double price;
  final int quantity;
  final String description;
  final String createdAt;

  SqliteMedicine({
    this.id,
    required this.medicineName,
    required this.category,
    required this.price,
    required this.quantity,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'category': category,
      'price': price,
      'quantity': quantity,
      'description': description,
      'createdAt': createdAt,
    };
  }

  factory SqliteMedicine.fromMap(Map<String, dynamic> map) {
    return SqliteMedicine(
      id: map['id'] as int?,
      medicineName: map['medicineName'] as String,
      category: map['category'] as String,
      price: map['price'] as double,
      quantity: map['quantity'] as int,
      description: map['description'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}
