enum SortOption { relevance, priceLowHigh, priceHighLow, ratingHighLow }

extension SortOptionExtension on SortOption {
  String get urlValue {
    switch (this) {
      case SortOption.relevance:
        return 'relevance';
      case SortOption.priceLowHigh:
        return 'price-low';
      case SortOption.priceHighLow:
        return 'price-high';
      case SortOption.ratingHighLow:
        return 'rating-high';
    }
  }

  static SortOption? fromUrlValue(String? value) {
    switch (value) {
      case 'relevance':
        return SortOption.relevance;
      case 'price-low':
        return SortOption.priceLowHigh;
      case 'price-high':
        return SortOption.priceHighLow;
      case 'rating-high':
        return SortOption.ratingHighLow;
      default:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.priceLowHigh:
        return 'Price: Low to High';
      case SortOption.priceHighLow:
        return 'Price: High to Low';
      case SortOption.ratingHighLow:
        return 'Rating: Highest First';
    }
  }
}

