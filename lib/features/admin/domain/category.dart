import 'dart:typed_data';

class Category {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? parentId;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Local properties for image handling
  final Uint8List? imageBytes;
  final String? imageName;
  
  // Computed property for product count (can be fetched separately)
  final int productCount;

  const Category({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.imageBytes,
    this.imageName,
    this.productCount = 0,
  });

  // Factory constructor for creating from Supabase JSON
  factory Category.fromSupabaseJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      parentId: json['parent_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      productCount: json['product_count'] as int? ?? 0,
    );
  }

  // Convert to JSON for Supabase operations
  Map<String, dynamic> toSupabaseJson() {
    return {
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Copy with method for immutable updates
  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? parentId,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Uint8List? imageBytes,
    String? imageName,
    int? productCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
      productCount: productCount ?? this.productCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, description: $description, isActive: $isActive)';
  }
}