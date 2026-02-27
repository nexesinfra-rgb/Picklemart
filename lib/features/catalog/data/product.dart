import 'measurement.dart';

class Product {
  final String id;
  final String name; // title
  final String? subtitle;
  final String imageUrl; // primary image
  final List<String> images; // gallery
  final double price; // base or min variant price (selling price)
  final double? costPrice; // cost price (for manufacturer billing)
  final double? tax; // tax percentage applicable to selling price only
  final String? brand;
  final String? sku; // for single-variant products
  final int stock; // aggregate/for single-variant
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? description;
  final List<String> tags;
  final List<String> categories;
  final List<Variant> variants; // variant matrix
  final ProductMeasurement? measurement; // measurement-based pricing
  final List<String> alternativeNames; // alternative names for search
  final bool isFeatured;
  final int featuredPosition;
  final double? averageRating; // Average rating (0.00 to 5.00)
  final int ratingCount; // Total number of ratings
  final bool isOutOfStock; // Boolean flag to mark product as unavailable

  const Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.images,
    required this.price,
    this.costPrice,
    this.tax,
    this.subtitle,
    this.brand,
    this.sku,
    this.createdAt,
    this.updatedAt,
    this.stock = 0,
    this.description,
    this.tags = const [],
    this.categories = const [],
    this.variants = const [],
    this.measurement,
    this.alternativeNames = const [],
    this.isFeatured = false,
    this.featuredPosition = 0,
    this.averageRating,
    this.ratingCount = 0,
    this.isOutOfStock = false,
  });

  bool get hasMeasurementPricing => measurement != null;

  /// Get the final price including tax
  /// Returns: price + (price * tax / 100) if tax exists, otherwise just price
  double get finalPrice {
    if (tax != null && tax! > 0) {
      return price + (price * tax! / 100);
    }
    return price;
  }

  // Note: isOutOfStock is now a field that can be accessed directly
  // This flag is controlled by admins and makes products appear unavailable to customers
  // regardless of stock quantity (for seasonal/unavailable products)
}

class Variant {
  final String? id;
  final String sku;
  final Map<String, String> attributes; // e.g., {'Size':'M','Color':'Black'}
  final double price; // selling price
  final double? costPrice; // cost price (for manufacturer billing)
  final double? tax; // tax percentage applicable to selling price only
  final int stock;
  final List<String> images;

  const Variant({
    this.id,
    required this.sku,
    required this.attributes,
    required this.price,
    this.costPrice,
    this.tax,
    this.stock = 0,
    this.images = const [],
  });

  /// Get the final price including tax
  /// Returns: price + (price * tax / 100) if tax exists, otherwise just price
  double get finalPrice {
    if (tax != null && tax! > 0) {
      return price + (price * tax! / 100);
    }
    return price;
  }

  /// Get the final price including tax, with fallback to product tax
  /// Used when variant doesn't have its own tax but product does
  double finalPriceWithFallback(double? productTax) {
    final taxToUse = tax ?? productTax;
    if (taxToUse != null && taxToUse > 0) {
      return price + (price * taxToUse / 100);
    }
    return price;
  }
}
