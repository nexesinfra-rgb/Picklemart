class InventoryItem {
  final String productId;
  final String productName;
  final int currentStock;
  final int minStockThreshold;
  final DateTime lastUpdated;
  final List<String> suppliers;

  const InventoryItem({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minStockThreshold,
    required this.lastUpdated,
    this.suppliers = const [],
  });

  InventoryItem copyWith({
    String? productId,
    String? productName,
    int? currentStock,
    int? minStockThreshold,
    DateTime? lastUpdated,
    List<String>? suppliers,
  }) {
    return InventoryItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      currentStock: currentStock ?? this.currentStock,
      minStockThreshold: minStockThreshold ?? this.minStockThreshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      suppliers: suppliers ?? this.suppliers,
    );
  }
}

class StockAlert {
  final String id;
  final String productId;
  final String productName;
  final int currentStock;
  final int threshold;
  final DateTime createdAt;
  final bool isResolved;

  const StockAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.threshold,
    required this.createdAt,
    this.isResolved = false,
  });

  StockAlert copyWith({
    String? id,
    String? productId,
    String? productName,
    int? currentStock,
    int? threshold,
    DateTime? createdAt,
    bool? isResolved,
  }) {
    return StockAlert(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      currentStock: currentStock ?? this.currentStock,
      threshold: threshold ?? this.threshold,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}
