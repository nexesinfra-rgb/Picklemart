/// Utility functions for order-related operations
class OrderUtils {
  /// Get the formatted order number for display
  /// Returns the full order number as-is (e.g. "4700", "4701", "ORD-123")
  static String formatOrderNumber(String orderNum) {
    return orderNum;
  }

  /// Parse Old Due amount from notes
  static double parseOldDueFromNotes(String? notes) {
    if (notes == null) return 0.0;
    // Match "Old Due: ₹100.00" or "Old Due: Rs 100.00"
    final match = RegExp(r'Old Due: (?:₹|Rs\s*)([\d\.]+)').firstMatch(notes);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }
}
