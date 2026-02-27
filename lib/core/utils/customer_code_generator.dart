/// Utility to generate customer codes from customer data
class CustomerCodeGenerator {
  /// Generate a customer code from customer information
  /// Format: Prefix-Location-Initials
  /// Example: F71-BNDLGD-TS (where BNDLGD is location code, TS is state)
  static String generate({
    required String customerName,
    required String? city,
    required String? state,
    String? customerId,
  }) {
    // Extract initials from customer name (first letter + first letter of each word)
    String initials = _extractInitials(customerName);
    
    // Generate location code from city/address
    String locationCode = _generateLocationCode(city ?? '', state ?? '');
    
    // Use first character of customer ID or generate a prefix
    String prefix = 'F';
    if (customerId != null && customerId.isNotEmpty) {
      // Use last 2 digits or characters from ID
      final idSuffix = customerId.length >= 2 
          ? customerId.substring(customerId.length - 2) 
          : customerId;
      prefix = 'F$idSuffix';
    } else {
      // Generate random-like prefix from name
      final nameHash = customerName.hashCode.abs();
      prefix = 'F${(nameHash % 100).toString().padLeft(2, '0')}';
    }
    
    // Format: Prefix-LocationCode-Initials
    return '$prefix-$locationCode-$initials';
  }

  /// Extract initials from customer name
  /// Example: "MOIGARI NAVEENA" -> "MN"
  static String _extractInitials(String name) {
    if (name.isEmpty) return 'XX';
    
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'XX';
    
    if (words.length == 1) {
      // Single word - take first two letters
      final word = words[0];
      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      }
      return word.toUpperCase().padRight(2, 'X');
    }
    
    // Multiple words - take first letter of first word and first letter of last word
    final first = words.first.isNotEmpty ? words.first[0].toUpperCase() : 'X';
    final last = words.last.isNotEmpty ? words.last[0].toUpperCase() : 'X';
    return '$first$last';
  }

  /// Generate location code from city and state
  /// Example: "BANDLAGUDA" + "Telangana" -> "BNDLGD" or "HYD" for Hyderabad
  static String _generateLocationCode(String city, String state) {
    // Common city codes
    final cityUpper = city.toUpperCase().trim();
    final stateUpper = state.toUpperCase().trim();
    
    // Predefined city codes
    if (cityUpper.contains('HYDERABAD') || cityUpper.contains('HYD')) {
      return 'HYD';
    }
    if (cityUpper.contains('MUMBAI') || cityUpper.contains('BOM')) {
      return 'BOM';
    }
    if (cityUpper.contains('DELHI')) {
      return 'DEL';
    }
    if (cityUpper.contains('BANGALORE') || cityUpper.contains('BENGALURU')) {
      return 'BLR';
    }
    if (cityUpper.contains('CHENNAI') || cityUpper.contains('MADRAS')) {
      return 'MAA';
    }
    
    // Generate from city name - take first few consonants
    if (cityUpper.isNotEmpty) {
      final consonants = cityUpper.replaceAll(RegExp(r'[AEIOU\s]'), '');
      if (consonants.length >= 3) {
        return consonants.substring(0, consonants.length > 6 ? 6 : consonants.length);
      }
      // If not enough consonants, use first 3-6 characters
      final code = cityUpper.replaceAll(RegExp(r'\s'), '').substring(
        0, 
        cityUpper.length > 6 ? 6 : cityUpper.length,
      );
      return code;
    }
    
    // Fallback to state code
    if (stateUpper.isNotEmpty) {
      if (stateUpper.contains('TELANGANA')) return 'TS';
      if (stateUpper.contains('ANDHRA')) return 'AP';
      if (stateUpper.contains('MAHARASHTRA')) return 'MH';
      if (stateUpper.contains('TAMIL')) return 'TN';
      if (stateUpper.contains('KARNATAKA')) return 'KA';
      
      // Take first 3-6 letters of state
      final stateCode = stateUpper.replaceAll(RegExp(r'\s'), '').substring(
        0, 
        stateUpper.length > 6 ? 6 : stateUpper.length,
      );
      return stateCode;
    }
    
    return 'LOC';
  }
}

