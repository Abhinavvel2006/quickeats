class OrderLine {
  final int foodId;
  final String name;
  final int pricePaise;
  final int quantity;
  const OrderLine({required this.foodId, required this.name,
    required this.pricePaise, required this.quantity});
  int get totalPaise => pricePaise * quantity;
  factory OrderLine.fromMap(Map<String, Object?> r) => OrderLine(
    foodId: r['food_id'] as int, name: r['name'] as String,
    pricePaise: r['price_paise'] as int, quantity: r['quantity'] as int);
}

class OrderRecord {
  final String id;
  final String createdAt;
  final int totalPaise;
  final String method;
  final String status;
  final String? razorpayOrderId;
  final String? keyId;
  final String? paymentId;
  final String? signature;
  final List<OrderLine> items;
  const OrderRecord({required this.id, required this.createdAt,
    required this.totalPaise, required this.method, required this.status,
    required this.items, this.razorpayOrderId, this.keyId,
    this.paymentId, this.signature});
  bool get confirmed => status == 'confirmed';
  bool get paid => confirmed && method == 'razorpay';
  factory OrderRecord.fromMap(Map<String, Object?> r, List<OrderLine> lines) =>
    OrderRecord(id: r['id'] as String, createdAt: r['created_at'] as String,
      totalPaise: r['total_paise'] as int, method: r['method'] as String,
      status: r['status'] as String, items: List.unmodifiable(lines),
      razorpayOrderId: r['razorpay_order_id'] as String?,
      keyId: r['key_id'] as String?, paymentId: r['payment_id'] as String?,
      signature: r['signature'] as String?);
}

String money(int paise) => '₹${(paise / 100).toStringAsFixed(2)}';
