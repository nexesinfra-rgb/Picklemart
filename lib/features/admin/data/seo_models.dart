enum SEOPriority { low, normal, high, critical }

enum SEOStatus { pending, in_progress, completed, failed }

class SEOAnalysis {
  final String id;
  final String url;
  final String title;
  final String description;
  final int score;
  final List<SEOIssue> issues;
  final List<SEOSuggestion> suggestions;
  final Map<String, dynamic> metrics;
  final DateTime analyzedAt;
  final DateTime updatedAt;

  const SEOAnalysis({
    required this.id,
    required this.url,
    required this.title,
    required this.description,
    required this.score,
    this.issues = const [],
    this.suggestions = const [],
    this.metrics = const {},
    required this.analyzedAt,
    required this.updatedAt,
  });

  SEOAnalysis copyWith({
    String? id,
    String? url,
    String? title,
    String? description,
    int? score,
    List<SEOIssue>? issues,
    List<SEOSuggestion>? suggestions,
    Map<String, dynamic>? metrics,
    DateTime? analyzedAt,
    DateTime? updatedAt,
  }) {
    return SEOAnalysis(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      score: score ?? this.score,
      issues: issues ?? this.issues,
      suggestions: suggestions ?? this.suggestions,
      metrics: metrics ?? this.metrics,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SEOIssue {
  final String id;
  final String type;
  final String title;
  final String description;
  final SEOPriority priority;
  final String? solution;
  final bool isFixed;
  final DateTime createdAt;

  const SEOIssue({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    this.solution,
    this.isFixed = false,
    required this.createdAt,
  });

  SEOIssue copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    SEOPriority? priority,
    String? solution,
    bool? isFixed,
    DateTime? createdAt,
  }) {
    return SEOIssue(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      solution: solution ?? this.solution,
      isFixed: isFixed ?? this.isFixed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SEOSuggestion {
  final String id;
  final String type;
  final String title;
  final String description;
  final SEOPriority priority;
  final String? implementation;
  final bool isImplemented;
  final DateTime createdAt;

  const SEOSuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    this.implementation,
    this.isImplemented = false,
    required this.createdAt,
  });

  SEOSuggestion copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    SEOPriority? priority,
    String? implementation,
    bool? isImplemented,
    DateTime? createdAt,
  }) {
    return SEOSuggestion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      implementation: implementation ?? this.implementation,
      isImplemented: isImplemented ?? this.isImplemented,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SEOMetaTag {
  final String id;
  final String name;
  final String content;
  final String? property;
  final String? httpEquiv;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SEOMetaTag({
    required this.id,
    required this.name,
    required this.content,
    this.property,
    this.httpEquiv,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  SEOMetaTag copyWith({
    String? id,
    String? name,
    String? content,
    String? property,
    String? httpEquiv,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SEOMetaTag(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      property: property ?? this.property,
      httpEquiv: httpEquiv ?? this.httpEquiv,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SEOSitemap {
  final String id;
  final String url;
  final double priority;
  final String changeFrequency;
  final DateTime lastModified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SEOSitemap({
    required this.id,
    required this.url,
    required this.priority,
    required this.changeFrequency,
    required this.lastModified,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  SEOSitemap copyWith({
    String? id,
    String? url,
    double? priority,
    String? changeFrequency,
    DateTime? lastModified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SEOSitemap(
      id: id ?? this.id,
      url: url ?? this.url,
      priority: priority ?? this.priority,
      changeFrequency: changeFrequency ?? this.changeFrequency,
      lastModified: lastModified ?? this.lastModified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SEORobotsTxt {
  final String id;
  final String content;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SEORobotsTxt({
    required this.id,
    required this.content,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  SEORobotsTxt copyWith({
    String? id,
    String? content,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SEORobotsTxt(
      id: id ?? this.id,
      content: content ?? this.content,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
