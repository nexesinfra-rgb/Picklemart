enum MeasurementUnit {
  kg,
  gram,
  liter,
  ml,
  piece,
  dozen,
  pack,
  box,
  bag,
  bottle,
  can,
  roll,
  meter,
  cm,
  inch,
  foot,
  yard,
}

extension MeasurementUnitExtension on MeasurementUnit {
  String get displayName {
    switch (this) {
      case MeasurementUnit.kg:
        return 'Kilogram';
      case MeasurementUnit.gram:
        return 'Gram';
      case MeasurementUnit.liter:
        return 'Liter';
      case MeasurementUnit.ml:
        return 'Milliliter';
      case MeasurementUnit.piece:
        return 'Piece';
      case MeasurementUnit.dozen:
        return 'Dozen';
      case MeasurementUnit.pack:
        return 'Pack';
      case MeasurementUnit.box:
        return 'Box';
      case MeasurementUnit.bag:
        return 'Bag';
      case MeasurementUnit.bottle:
        return 'Bottle';
      case MeasurementUnit.can:
        return 'Can';
      case MeasurementUnit.roll:
        return 'Roll';
      case MeasurementUnit.meter:
        return 'Meter';
      case MeasurementUnit.cm:
        return 'Centimeter';
      case MeasurementUnit.inch:
        return 'Inch';
      case MeasurementUnit.foot:
        return 'Foot';
      case MeasurementUnit.yard:
        return 'Yard';
    }
  }

  String get shortName {
    switch (this) {
      case MeasurementUnit.kg:
        return 'kg';
      case MeasurementUnit.gram:
        return 'g';
      case MeasurementUnit.liter:
        return 'L';
      case MeasurementUnit.ml:
        return 'ml';
      case MeasurementUnit.piece:
        return 'pc';
      case MeasurementUnit.dozen:
        return 'dz';
      case MeasurementUnit.pack:
        return 'pack';
      case MeasurementUnit.box:
        return 'box';
      case MeasurementUnit.bag:
        return 'bag';
      case MeasurementUnit.bottle:
        return 'bottle';
      case MeasurementUnit.can:
        return 'can';
      case MeasurementUnit.roll:
        return 'roll';
      case MeasurementUnit.meter:
        return 'm';
      case MeasurementUnit.cm:
        return 'cm';
      case MeasurementUnit.inch:
        return 'in';
      case MeasurementUnit.foot:
        return 'ft';
      case MeasurementUnit.yard:
        return 'yd';
    }
  }

  // Conversion factors to base unit (gram for weight, ml for volume, piece for count)
  double get conversionFactor {
    switch (this) {
      case MeasurementUnit.kg:
        return 1000.0; // 1 kg = 1000 grams
      case MeasurementUnit.gram:
        return 1.0; // Base unit for weight
      case MeasurementUnit.liter:
        return 1000.0; // 1 L = 1000 ml
      case MeasurementUnit.ml:
        return 1.0; // Base unit for volume
      case MeasurementUnit.piece:
        return 1.0; // Base unit for count
      case MeasurementUnit.dozen:
        return 12.0; // 1 dozen = 12 pieces
      case MeasurementUnit.pack:
        return 1.0; // Varies by product
      case MeasurementUnit.box:
        return 1.0; // Varies by product
      case MeasurementUnit.bag:
        return 1.0; // Varies by product
      case MeasurementUnit.bottle:
        return 1.0; // Varies by product
      case MeasurementUnit.can:
        return 1.0; // Varies by product
      case MeasurementUnit.roll:
        return 1.0; // Varies by product
      case MeasurementUnit.meter:
        return 100.0; // 1 m = 100 cm
      case MeasurementUnit.cm:
        return 1.0; // Base unit for length
      case MeasurementUnit.inch:
        return 2.54; // 1 inch = 2.54 cm
      case MeasurementUnit.foot:
        return 30.48; // 1 ft = 30.48 cm
      case MeasurementUnit.yard:
        return 91.44; // 1 yd = 91.44 cm
    }
  }

  MeasurementUnit get baseUnit {
    switch (this) {
      case MeasurementUnit.kg:
      case MeasurementUnit.gram:
        return MeasurementUnit.gram;
      case MeasurementUnit.liter:
      case MeasurementUnit.ml:
        return MeasurementUnit.ml;
      case MeasurementUnit.piece:
      case MeasurementUnit.dozen:
      case MeasurementUnit.pack:
      case MeasurementUnit.box:
      case MeasurementUnit.bag:
      case MeasurementUnit.bottle:
      case MeasurementUnit.can:
      case MeasurementUnit.roll:
        return MeasurementUnit.piece;
      case MeasurementUnit.meter:
      case MeasurementUnit.cm:
      case MeasurementUnit.inch:
      case MeasurementUnit.foot:
      case MeasurementUnit.yard:
        return MeasurementUnit.cm;
    }
  }
}

class MeasurementPricing {
  final MeasurementUnit unit;
  final double price;
  final int stock;
  final double? weight; // in base unit (grams)
  final double? volume; // in base unit (ml)
  final double? length; // in base unit (cm)
  final int? count; // for countable items

  const MeasurementPricing({
    required this.unit,
    required this.price,
    this.stock = 0,
    this.weight,
    this.volume,
    this.length,
    this.count,
  });

  // Calculate price per base unit
  double get pricePerBaseUnit {
    final baseUnit = unit.baseUnit;
    final conversionFactor = unit.conversionFactor;

    if (baseUnit == MeasurementUnit.gram && weight != null) {
      return price / (weight! * conversionFactor);
    } else if (baseUnit == MeasurementUnit.ml && volume != null) {
      return price / (volume! * conversionFactor);
    } else if (baseUnit == MeasurementUnit.cm && length != null) {
      return price / (length! * conversionFactor);
    } else if (baseUnit == MeasurementUnit.piece && count != null) {
      return price / (count! * conversionFactor);
    }

    return price / conversionFactor;
  }

  // Convert price to different unit
  double convertPriceToUnit(MeasurementUnit targetUnit) {
    if (unit == targetUnit) return price;

    final baseUnit = unit.baseUnit;
    final targetBaseUnit = targetUnit.baseUnit;

    if (baseUnit != targetBaseUnit) {
      throw ArgumentError('Cannot convert between different measurement types');
    }

    final pricePerBase = pricePerBaseUnit;
    return pricePerBase * targetUnit.conversionFactor;
  }

  MeasurementPricing copyWith({
    MeasurementUnit? unit,
    double? price,
    int? stock,
    double? weight,
    double? volume,
    double? length,
    int? count,
  }) {
    return MeasurementPricing(
      unit: unit ?? this.unit,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      weight: weight ?? this.weight,
      volume: volume ?? this.volume,
      length: length ?? this.length,
      count: count ?? this.count,
    );
  }
}

class ProductMeasurement {
  final String productId;
  final List<MeasurementPricing> pricingOptions;
  final MeasurementUnit defaultUnit;
  final String? category; // e.g., 'weight', 'volume', 'count', 'length'

  const ProductMeasurement({
    required this.productId,
    required this.pricingOptions,
    required this.defaultUnit,
    this.category,
  });

  MeasurementPricing? getPricingForUnit(MeasurementUnit unit) {
    try {
      return pricingOptions.firstWhere((pricing) => pricing.unit == unit);
    } catch (e) {
      return null;
    }
  }

  List<MeasurementUnit> get availableUnits {
    return pricingOptions.map((pricing) => pricing.unit).toList();
  }

  double? getPriceForUnit(MeasurementUnit unit) {
    final pricing = getPricingForUnit(unit);
    return pricing?.price;
  }

  int? getStockForUnit(MeasurementUnit unit) {
    final pricing = getPricingForUnit(unit);
    return pricing?.stock;
  }

  bool hasDiscountForUnit(MeasurementUnit unit) {
    // No discount logic since compareAtPrice has been removed
    return false;
  }
}
