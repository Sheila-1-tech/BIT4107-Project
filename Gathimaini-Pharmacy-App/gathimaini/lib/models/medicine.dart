class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    this.category,
    this.imageUrl,
    this.stockQuantity = 100,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final double rating;
  final String? category;
  final String? imageUrl;
  final int stockQuantity;

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
      stockQuantity: json['stockQuantity'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'rating': rating,
    'category': category,
    'imageUrl': imageUrl,
    'stockQuantity': stockQuantity,
  };

  // SQLite Helpers
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      rating: (map['rating'] as num).toDouble(),
      category: map['category'] as String?,
      imageUrl: map['imageUrl'] as String?,
      stockQuantity: map['stockQuantity'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'rating': rating,
      'category': category,
      'imageUrl': imageUrl,
      'stockQuantity': stockQuantity,
    };
  }
}
