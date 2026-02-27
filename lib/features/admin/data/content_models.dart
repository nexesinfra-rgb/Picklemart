enum ContentType { page, blog, product, category, custom }

enum ContentStatus { draft, published, archived, scheduled }

enum ContentVisibility { public, private, password_protected }

class ContentItem {
  final String id;
  final String title;
  final String slug;
  final String content;
  final String excerpt;
  final ContentType type;
  final ContentStatus status;
  final ContentVisibility visibility;
  final List<String> tags;
  final List<String> categories;
  final String featuredImage;
  final String authorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final DateTime? scheduledAt;
  final Map<String, dynamic> metaData;
  final int viewCount;
  final int commentCount;
  final bool allowComments;
  final String? password;

  const ContentItem({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.excerpt,
    required this.type,
    required this.status,
    required this.visibility,
    this.tags = const [],
    this.categories = const [],
    this.featuredImage = '',
    required this.authorId,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.scheduledAt,
    this.metaData = const {},
    this.viewCount = 0,
    this.commentCount = 0,
    this.allowComments = true,
    this.password,
  });

  ContentItem copyWith({
    String? id,
    String? title,
    String? slug,
    String? content,
    String? excerpt,
    ContentType? type,
    ContentStatus? status,
    ContentVisibility? visibility,
    List<String>? tags,
    List<String>? categories,
    String? featuredImage,
    String? authorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    DateTime? scheduledAt,
    Map<String, dynamic>? metaData,
    int? viewCount,
    int? commentCount,
    bool? allowComments,
    String? password,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      content: content ?? this.content,
      excerpt: excerpt ?? this.excerpt,
      type: type ?? this.type,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      tags: tags ?? this.tags,
      categories: categories ?? this.categories,
      featuredImage: featuredImage ?? this.featuredImage,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      metaData: metaData ?? this.metaData,
      viewCount: viewCount ?? this.viewCount,
      commentCount: commentCount ?? this.commentCount,
      allowComments: allowComments ?? this.allowComments,
      password: password ?? this.password,
    );
  }
}

class ContentCategory {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String? parentId;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  ContentCategory copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? parentId,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ContentComment {
  final String id;
  final String contentId;
  final String authorName;
  final String authorEmail;
  final String content;
  final String? parentId;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentComment({
    required this.id,
    required this.contentId,
    required this.authorName,
    required this.authorEmail,
    required this.content,
    this.parentId,
    this.isApproved = false,
    required this.createdAt,
    required this.updatedAt,
  });

  ContentComment copyWith({
    String? id,
    String? contentId,
    String? authorName,
    String? authorEmail,
    String? content,
    String? parentId,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentComment(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
