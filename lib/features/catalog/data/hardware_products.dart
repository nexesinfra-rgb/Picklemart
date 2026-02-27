import 'product.dart';

class HardwareProducts {
  static List<Product> getProducts() {
    return [
      // PICKLES CATEGORY (20 products)
      ..._createPicklesProducts(),
      // KARAM PODIS CATEGORY (20 products)
      ..._createKaramPodisProducts(),
      // SPICE POWDERS CATEGORY (20 products)
      ..._createSpicePowdersProducts(),
      // MASALAS CATEGORY (20 products)
      ..._createMasalasProducts(),
    ];
  }

  static List<Product> _createPicklesProducts() {
    final baseImages = [
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
    ];

    return List.generate(20, (index) {
      final i = index + 1;
      return Product(
        id: 'pickle_$i',
        name: _getPickleName(i),
        subtitle: _getPickleSubtitle(i),
        imageUrl: baseImages[i % baseImages.length],
        images: baseImages,
        price: 150.0 + (i * 25.0),
        brand: _getPickleBrand(i),
        stock: 50 + (i * 5),
        description: _getPickleDescription(i),
        tags: ['pickle', 'homemade', 'traditional'],
        categories: ['Pickles'],
        variants: [],
        alternativeNames: _getPickleAlternativeNames(i),
      );
    });
  }

  static List<Product> _createKaramPodisProducts() {
    final baseImages = [
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
    ];

    return List.generate(20, (index) {
      final i = index + 1;
      return Product(
        id: 'karam_podi_$i',
        name: _getKaramPodiName(i),
        subtitle: _getKaramPodiSubtitle(i),
        imageUrl: baseImages[i % baseImages.length],
        images: baseImages,
        price: 120.0 + (i * 20.0),
        brand: _getKaramPodiBrand(i),
        stock: 75 + (i * 8),
        description: _getKaramPodiDescription(i),
        tags: ['karam-podi', 'spice-mix', 'gunpowder'],
        categories: ['Karam Podis'],
        variants: [],
        alternativeNames: _getKaramPodiAlternativeNames(i),
      );
    });
  }

  static List<Product> _createSpicePowdersProducts() {
    final baseImages = [
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
    ];

    return List.generate(20, (index) {
      final i = index + 1;
      return Product(
        id: 'spice_powder_$i',
        name: _getSpicePowderName(i),
        subtitle: _getSpicePowderSubtitle(i),
        imageUrl: baseImages[i % baseImages.length],
        images: baseImages,
        price: 80.0 + (i * 15.0),
        brand: _getSpicePowderBrand(i),
        sku: 'SP-${i.toString().padLeft(3, '0')}',
        stock: 100 + (i * 10),
        description: _getSpicePowderDescription(i),
        tags: ['spice', 'powder', 'masala'],
        categories: ['Spice Powders'],
        variants: [],
        alternativeNames: _getSpicePowderAlternativeNames(i),
      );
    });
  }

  static List<Product> _createMasalasProducts() {
    final baseImages = [
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
      'assets/picklemart.png',
    ];

    return List.generate(20, (index) {
      final i = index + 1;
      return Product(
        id: 'masala_$i',
        name: _getMasalaName(i),
        subtitle: _getMasalaSubtitle(i),
        imageUrl: baseImages[i % baseImages.length],
        images: baseImages,
        price: 200.0 + (i * 30.0),
        brand: _getMasalaBrand(i),
        stock: 40 + (i * 4),
        description: _getMasalaDescription(i),
        tags: ['masala', 'spice-mix', 'traditional'],
        categories: ['Masalas'],
        variants: [],
        alternativeNames: _getMasalaAlternativeNames(i),
      );
    });
  }

  // Helper methods for pickles
  static String _getPickleName(int i) {
    final names = [
      'Mango Pickle',
      'Lemon Pickle',
      'Mixed Vegetable Pickle',
      'Ginger Pickle',
      'Garlic Pickle',
      'Chilli Pickle',
      'Carrot Pickle',
      'Cauliflower Pickle',
      'Onion Pickle',
      'Tomato Pickle',
      'Brinjal Pickle',
      'Cucumber Pickle',
      'Green Mango Pickle',
      'Sweet Mango Pickle',
      'Avakkai Pickle',
      'Lime Pickle',
      'Red Chilli Pickle',
      'Green Chilli Pickle',
      'Mixed Pickle',
      'Traditional Pickle',
    ];
    return names[(i - 1) % names.length];
  }

  static String _getPickleSubtitle(int i) {
    final subtitles = [
      'Homemade',
      'Traditional',
      'Spicy',
      'Tangy',
      'Authentic',
      'Fresh',
      'Classic',
      'Premium',
      'Special',
      'Delicious',
      'Homemade',
      'Traditional',
      'Spicy',
      'Tangy',
      'Authentic',
      'Fresh',
      'Classic',
      'Premium',
      'Special',
      'Delicious',
    ];
    return subtitles[(i - 1) % subtitles.length];
  }

  static String _getPickleBrand(int i) {
    final brands = [
      'Pickle Mart',
      'Homemade',
      'Traditional',
      'Grandma\'s',
      'Authentic',
    ];
    return brands[(i - 1) % brands.length];
  }

  static List<String> _getPickleHighlights(int i) {
    final highlights = [
      ['No Preservatives', 'Fresh Ingredients', 'Homemade'],
      ['Traditional Recipe', 'Authentic Taste', 'Premium Quality'],
      ['Spicy & Tangy', 'Long Shelf Life', 'Fresh'],
      ['Natural Ingredients', 'Traditional', 'Delicious'],
      ['Homemade', 'Authentic', 'Premium'],
    ];
    return highlights[(i - 1) % highlights.length];
  }

  static String _getPickleDescription(int i) {
    return '${_getPickleSubtitle(i)} ${_getPickleName(i).toLowerCase()} made with ${_getPickleHighlights(i).join(', ').toLowerCase()}. Perfect accompaniment to any meal.';
  }

  // Helper methods for karam podis
  static String _getKaramPodiName(int i) {
    final names = [
      'Idli Karam Podi',
      'Dosa Karam Podi',
      'Gunpowder',
      'Red Chilli Podi',
      'Sesame Karam Podi',
      'Peanut Karam Podi',
      'Coconut Karam Podi',
      'Mixed Karam Podi',
      'Spicy Karam Podi',
      'Traditional Karam Podi',
      'Garlic Karam Podi',
      'Onion Karam Podi',
      'Tomato Karam Podi',
      'Curry Leaf Karam Podi',
      'Coriander Karam Podi',
      'Mint Karam Podi',
      'Dry Chutney Podi',
      'Spice Mix Podi',
      'Hot Karam Podi',
      'Classic Karam Podi',
    ];
    return names[(i - 1) % names.length];
  }

  static String _getKaramPodiSubtitle(int i) {
    final subtitles = [
      'Spicy',
      'Traditional',
      'Authentic',
      'Hot',
      'Flavorful',
      'Classic',
      'Premium',
      'Special',
      'Delicious',
      'Homemade',
      'Spicy',
      'Traditional',
      'Authentic',
      'Hot',
      'Flavorful',
      'Classic',
      'Premium',
      'Special',
      'Delicious',
      'Homemade',
    ];
    return subtitles[(i - 1) % subtitles.length];
  }

  static String _getKaramPodiBrand(int i) {
    final brands = [
      'Pickle Mart',
      'Homemade',
      'Traditional',
      'Spice Master',
      'Authentic',
    ];
    return brands[(i - 1) % brands.length];
  }

  static List<String> _getKaramPodiHighlights(int i) {
    final highlights = [
      ['Roasted Spices', 'Authentic Taste', 'Spicy'],
      ['Traditional Recipe', 'Fresh Ground', 'Premium Quality'],
      ['No Preservatives', 'Natural', 'Flavorful'],
      ['Hot & Spicy', 'Long Shelf Life', 'Fresh'],
      ['Homemade', 'Authentic', 'Premium'],
    ];
    return highlights[(i - 1) % highlights.length];
  }

  static String _getKaramPodiDescription(int i) {
    return '${_getKaramPodiSubtitle(i)} ${_getKaramPodiName(i).toLowerCase()} with ${_getKaramPodiHighlights(i).join(', ').toLowerCase()}. Perfect for idli, dosa, and rice.';
  }

  // Helper methods for spice powders
  static String _getSpicePowderName(int i) {
    final names = [
      'Sambar Powder',
      'Rasam Powder',
      'Curry Powder',
      'Chicken Masala Powder',
      'Biryani Masala Powder',
      'Garam Masala Powder',
      'Chaat Masala Powder',
      'Pav Bhaji Masala',
      'Kitchen King Masala',
      'Sabzi Masala',
      'Dhania Powder',
      'Jeera Powder',
      'Haldi Powder',
      'Red Chilli Powder',
      'Coriander Powder',
      'Cumin Powder',
      'Turmeric Powder',
      'Black Pepper Powder',
      'Fenugreek Powder',
      'Traditional Spice Powder',
    ];
    return names[(i - 1) % names.length];
  }

  static String _getSpicePowderSubtitle(int i) {
    final subtitles = [
      'Authentic',
      'Traditional',
      'Premium',
      'Fresh',
      'Pure',
      'Classic',
      'Special',
      'Delicious',
      'Homemade',
      'Natural',
      'Authentic',
      'Traditional',
      'Premium',
      'Fresh',
      'Pure',
      'Classic',
      'Special',
      'Delicious',
      'Homemade',
      'Natural',
    ];
    return subtitles[(i - 1) % subtitles.length];
  }

  static String _getSpicePowderBrand(int i) {
    final brands = [
      'Pickle Mart',
      'Homemade',
      'Traditional',
      'Spice Master',
      'Authentic',
    ];
    return brands[(i - 1) % brands.length];
  }

  static List<String> _getSpicePowderHighlights(int i) {
    final highlights = [
      ['Fresh Ground', 'No Additives', 'Pure'],
      ['Traditional Recipe', 'Authentic Taste', 'Premium Quality'],
      ['Natural Ingredients', 'No Preservatives', 'Fresh'],
      ['Pure Spices', 'Long Shelf Life', 'Premium'],
      ['Homemade', 'Authentic', 'Traditional'],
    ];
    return highlights[(i - 1) % highlights.length];
  }

  static String _getSpicePowderDescription(int i) {
    return '${_getSpicePowderSubtitle(i)} ${_getSpicePowderName(i).toLowerCase()} with ${_getSpicePowderHighlights(i).join(', ').toLowerCase()}. Essential for authentic Indian cooking.';
  }

  // Helper methods for masalas
  static String _getMasalaName(int i) {
    final names = [
      'Garam Masala',
      'Chaat Masala',
      'Biryani Masala',
      'Tandoori Masala',
      'Pav Bhaji Masala',
      'Sambar Masala',
      'Rasam Masala',
      'Curry Masala',
      'Chicken Masala',
      'Mutton Masala',
      'Fish Masala',
      'Vegetable Masala',
      'Kitchen King Masala',
      'Sabzi Masala',
      'Dal Masala',
      'Mixed Masala',
      'Special Masala',
      'Traditional Masala',
      'Premium Masala',
      'Authentic Masala',
    ];
    return names[(i - 1) % names.length];
  }

  static String _getMasalaSubtitle(int i) {
    final subtitles = [
      'Authentic',
      'Traditional',
      'Premium',
      'Special',
      'Classic',
      'Delicious',
      'Flavorful',
      'Homemade',
      'Natural',
      'Pure',
      'Authentic',
      'Traditional',
      'Premium',
      'Special',
      'Classic',
      'Delicious',
      'Flavorful',
      'Homemade',
      'Natural',
      'Pure',
    ];
    return subtitles[(i - 1) % subtitles.length];
  }

  static String _getMasalaBrand(int i) {
    final brands = [
      'Pickle Mart',
      'Homemade',
      'Traditional',
      'Spice Master',
      'Authentic',
    ];
    return brands[(i - 1) % brands.length];
  }

  static List<String> _getMasalaHighlights(int i) {
    final highlights = [
      ['Blended Spices', 'Authentic Taste', 'Premium Quality'],
      ['Traditional Recipe', 'No Preservatives', 'Fresh'],
      ['Natural Ingredients', 'Long Shelf Life', 'Pure'],
      ['Homemade', 'Authentic', 'Delicious'],
      ['Premium Quality', 'Traditional', 'Flavorful'],
    ];
    return highlights[(i - 1) % highlights.length];
  }

  static String _getMasalaDescription(int i) {
    return '${_getMasalaSubtitle(i)} ${_getMasalaName(i).toLowerCase()} with ${_getMasalaHighlights(i).join(', ').toLowerCase()}. Perfect blend of spices for authentic Indian dishes.';
  }

  // Alternative names helper methods
  static List<String> _getPickleAlternativeNames(int i) {
    final alternatives = [
      ['Achar', 'Pickle', 'Indian Pickle'],
      ['Homemade Pickle', 'Traditional Pickle', 'Spicy Pickle'],
      ['Tangy Pickle', 'Authentic Pickle', 'Fresh Pickle'],
      ['Classic Pickle', 'Premium Pickle', 'Special Pickle'],
      ['Delicious Pickle', 'Traditional Achar', 'Homemade Achar'],
    ];
    return alternatives[(i - 1) % alternatives.length];
  }

  static List<String> _getKaramPodiAlternativeNames(int i) {
    final alternatives = [
      ['Gunpowder', 'Karam Podi', 'Spice Podi'],
      ['Idli Podi', 'Dosa Podi', 'Chutney Podi'],
      ['Spice Mix', 'Dry Chutney', 'Karam Podi Mix'],
      ['Traditional Podi', 'Homemade Podi', 'Authentic Podi'],
      ['Spicy Podi', 'Hot Podi', 'Classic Podi'],
    ];
    return alternatives[(i - 1) % alternatives.length];
  }

  static List<String> _getSpicePowderAlternativeNames(int i) {
    final alternatives = [
      ['Spice Powder', 'Masala Powder', 'Spice Mix'],
      ['Ground Spices', 'Powdered Spices', 'Spice Blend'],
      ['Traditional Powder', 'Homemade Powder', 'Authentic Powder'],
      ['Pure Spice', 'Natural Spice', 'Fresh Spice'],
      ['Premium Powder', 'Classic Powder', 'Special Powder'],
    ];
    return alternatives[(i - 1) % alternatives.length];
  }

  static List<String> _getMasalaAlternativeNames(int i) {
    final alternatives = [
      ['Spice Mix', 'Masala Mix', 'Blended Masala'],
      ['Traditional Masala', 'Homemade Masala', 'Authentic Masala'],
      ['Spice Blend', 'Masala Blend', 'Mixed Masala'],
      ['Premium Masala', 'Classic Masala', 'Special Masala'],
      ['Flavorful Masala', 'Delicious Masala', 'Pure Masala'],
    ];
    return alternatives[(i - 1) % alternatives.length];
  }
}
