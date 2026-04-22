class Product {
  final String id;
  final String name;
  final double buyingPrice;
  final double sellingPrice;
  int quantity;
  int lowStockThreshold;
  String category;
  bool isDeleted;

  Product({
    required this.id,
    required this.name,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.lowStockThreshold,
    this.category = 'General',
    this.isDeleted = false,
  });

  bool get isLowStock => quantity <= lowStockThreshold;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'lowStockThreshold': lowStockThreshold,
      'category': category,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      buyingPrice: _parseDouble(map['buyingPrice'] ?? map['buying_price']),
      sellingPrice: _parseDouble(map['sellingPrice'] ?? map['selling_price']),
      quantity: map['quantity'] as int,
      lowStockThreshold:
          map['lowStockThreshold'] ?? map['low_stock_threshold'] as int,
      category: map['category'] as String? ?? 'General',
      isDeleted:
          (map['isDeleted'] as int? ?? map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    }
    return value as double;
  }
}
