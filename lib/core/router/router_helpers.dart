/// Helper functions for building URLs with query parameters
class RouterHelpers {
  /// Build browse products URL with optional query parameters
  static String buildBrowseUrl(
    String kind,
    String value, {
    String? query,
    String? sort,
    bool? inStock,
    double? minRating,
  }) {
    final uri = Uri(
      path: '/browse/$kind/$value',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (inStock != null) 'inStock': inStock.toString(),
        if (minRating != null) 'minRating': minRating.toString(),
      },
    );
    return uri.toString();
  }

  /// Build search URL with query parameter and optional filters
  static String buildSearchUrl(
    String? query, {
    String? sort,
    double? minPrice,
    double? maxPrice,
    List<String>? categories,
    List<String>? brands,
    bool? inStock,
    double? minRating,
  }) {
    final queryParams = <String, String>{};
    
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
    }
    if (minPrice != null) {
      queryParams['minPrice'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParams['maxPrice'] = maxPrice.toString();
    }
    if (categories != null && categories.isNotEmpty) {
      queryParams['categories'] = categories.join(',');
    }
    if (brands != null && brands.isNotEmpty) {
      queryParams['brands'] = brands.join(',');
    }
    if (inStock != null) {
      queryParams['inStock'] = inStock.toString();
    }
    if (minRating != null) {
      queryParams['minRating'] = minRating.toString();
    }
    
    final uri = Uri(
      path: '/search',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return uri.toString();
  }
  
  /// Parse double from URL string
  static double? parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }
  
  /// Parse list of strings from comma-separated URL string
  static List<String> parseStringList(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').where((s) => s.trim().isNotEmpty).map((s) => s.trim()).toList();
  }

  /// Build admin products URL with optional query parameters
  static String buildAdminProductsUrl({
    String? query,
    String? category,
    bool? outOfStock,
  }) {
    final uri = Uri(
      path: '/admin/products',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null && category.isNotEmpty && category != 'All')
          'category': category,
        if (outOfStock != null && outOfStock) 'outOfStock': 'true',
      },
    );
    return uri.toString();
  }

  /// Build admin orders URL with optional query parameters
  static String buildAdminOrdersUrl({
    String? query,
    String? status,
    String? customerId,
  }) {
    final uri = Uri(
      path: '/admin/orders',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (status != null && status.isNotEmpty && status != 'all')
          'status': status,
        if (customerId != null && customerId.isNotEmpty)
          'customerId': customerId,
      },
    );
    return uri.toString();
  }

  /// Build orders URL with optional status filter
  static String buildOrdersUrl({String? status}) {
    final uri = Uri(
      path: '/orders',
      queryParameters: status != null && status.isNotEmpty && status != 'all'
          ? {'status': status}
          : null,
    );
    return uri.toString();
  }

  /// Build admin categories URL with optional search query
  static String buildAdminCategoriesUrl({String? query}) {
    final uri = Uri(
      path: '/admin/categories',
      queryParameters:
          query != null && query.isNotEmpty ? {'q': query} : null,
    );
    return uri.toString();
  }

  /// Build catalog URL with optional search query
  static String buildCatalogUrl({String? query}) {
    final uri = Uri(
      path: '/catalog',
      queryParameters:
          query != null && query.isNotEmpty ? {'q': query} : null,
    );
    return uri.toString();
  }

  /// Parse sort option from URL string
  static String? parseSortOption(String? sort) {
    if (sort == null || sort.isEmpty) return null;
    return sort;
  }

  /// Parse boolean from URL string
  static bool? parseBool(String? value) {
    if (value == null || value.isEmpty) return null;
    return value.toLowerCase() == 'true';
  }

  /// Update query parameters in current URI
  static Uri updateQueryParameters(
    Uri uri,
    Map<String, String?> updates,
  ) {
    final params = Map<String, String>.from(uri.queryParameters);
    
    for (final entry in updates.entries) {
      if (entry.value == null || entry.value!.isEmpty) {
        params.remove(entry.key);
      } else {
        params[entry.key] = entry.value!;
      }
    }
    
    return uri.replace(queryParameters: params.isEmpty ? null : params);
  }
}


