class Sale {
  final String productId;
  final DateTime date;
  final int quantity;

  Sale({
    required this.productId,
    required this.date,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'date': date.millisecondsSinceEpoch,
      'quantity': quantity,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      productId: map['productId'] as String? ?? map['product_id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      quantity: map['quantity'] as int,
    );
  }
}
