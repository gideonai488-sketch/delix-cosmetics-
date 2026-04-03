class OrderSummary {
  final String id;
  final String orderNumber;
  final DateTime createdAt;
  final double total;
  final String status;
  final List<String> items;

  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.total,
    required this.status,
    required this.items,
  });

  factory OrderSummary.fromMap(Map<String, dynamic> map) {
    final rawItems = map['order_items'];
    final itemNames = rawItems is List
        ? rawItems
            .map((item) => item is Map<String, dynamic>
                ? '${item['quantity'] ?? 1}x ${item['product_name'] ?? 'Item'}'
                : 'Item')
            .toList()
        : const <String>[];

    return OrderSummary(
      id: map['id'].toString(),
      orderNumber: map['order_number']?.toString() ?? map['id'].toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      total: (map['total'] is num)
          ? (map['total'] as num).toDouble()
          : double.tryParse(map['total']?.toString() ?? '') ?? 0,
      status: map['status']?.toString() ?? 'processing',
      items: itemNames,
    );
  }
}