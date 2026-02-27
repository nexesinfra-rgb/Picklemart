import 'order_model.dart';

class SavedOrderTemplate {
  final String id;
  final String userId;
  final String templateName;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedOrderTemplate({
    required this.id,
    required this.userId,
    required this.templateName,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'template_name': templateName,
      'items': items.map((item) => {
            'id': item.id,
            'name': item.name,
            'image': item.image,
            'price': item.price,
            'quantity': item.quantity,
            'size': item.size,
            'color': item.color,
          }).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SavedOrderTemplate.fromJson(Map<String, dynamic> json) {
    // Handle both DateTime objects and ISO strings
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      throw FormatException('Invalid date format: $value');
    }

    return SavedOrderTemplate(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      templateName: json['template_name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem(
                id: item['id'] as String,
                name: item['name'] as String,
                image: item['image'] as String,
                price: (item['price'] is num
                    ? (item['price'] as num).toDouble()
                    : double.parse(item['price'].toString())),
                quantity: item['quantity'] as int,
                size: item['size'] as String?,
                color: item['color'] as String?,
              ))
          .toList(),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  SavedOrderTemplate copyWith({
    String? id,
    String? userId,
    String? templateName,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedOrderTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateName: templateName ?? this.templateName,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

