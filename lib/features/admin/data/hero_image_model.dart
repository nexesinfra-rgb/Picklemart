/// Hero Image Model
/// Represents a hero section carousel image
class HeroImage {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? ctaText;
  final String? ctaLink;
  final String? slackUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  HeroImage({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.ctaText,
    this.ctaLink,
    this.slackUrl,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create HeroImage from JSON (database row)
  factory HeroImage.fromJson(Map<String, dynamic> json) {
    return HeroImage(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      ctaText: json['cta_text'] as String?,
      ctaLink: json['cta_link'] as String?,
      slackUrl: json['slack_url'] as String?,
      displayOrder: (json['display_order'] as int?) ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert HeroImage to JSON (for database operations)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'cta_text': ctaText,
      'cta_link': ctaLink,
      'slack_url': slackUrl,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  HeroImage copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? subtitle,
    String? ctaText,
    String? ctaLink,
    String? slackUrl,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HeroImage(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      ctaText: ctaText ?? this.ctaText,
      ctaLink: ctaLink ?? this.ctaLink,
      slackUrl: slackUrl ?? this.slackUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'HeroImage(id: $id, title: $title, displayOrder: $displayOrder, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HeroImage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

