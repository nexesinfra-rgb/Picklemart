/// Utility to convert numbers to words (Indian numbering system)
class NumberToWords {
  static const List<String> ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];

  static const List<String> tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety'
  ];

  /// Safe access to ones array with bounds checking
  static String _safeGetOnes(int index) {
    if (index >= 0 && index < ones.length) {
      return ones[index];
    }
    return ''; // Return empty string for invalid index
  }

  /// Safe access to tens array with bounds checking
  static String _safeGetTens(int index) {
    if (index >= 0 && index < tens.length) {
      return tens[index];
    }
    return ''; // Return empty string for invalid index
  }

  /// Convert number to words in Indian format
  static String convert(double amount) {
    // Input validation: handle edge cases
    if (amount.isNaN) {
      return 'Invalid Amount';
    }
    
    if (amount.isInfinite) {
      return amount.isNegative ? 'Negative Infinity Rupees only' : 'Infinity Rupees only';
    }
    
    if (amount < 0) {
      return 'Negative ${convert(-amount)}';
    }
    
    if (amount == 0) {
      return 'Zero Rupees only';
    }

    // Split into integer and decimal parts
    final parts = amount.toStringAsFixed(2).split('.');
    int rupees;
    int paise;
    
    try {
      rupees = int.parse(parts[0]);
      paise = int.parse(parts[1]);
    } catch (e) {
      // Fallback for parsing errors
      return 'Invalid Amount';
    }
    
    // Validate parsed values are reasonable
    if (rupees < 0 || paise < 0 || paise >= 100) {
      return 'Invalid Amount';
    }

    String result = _convertToWords(rupees);
    
    if (rupees == 1) {
      result += ' Rupee';
    } else {
      result += ' Rupees';
    }

    if (paise > 0) {
      result += ' and ${_convertToWords(paise)}';
      if (paise == 1) {
        result += ' Paise';
      } else {
        result += ' Paise';
      }
    }

    result += ' only';
    return result;
  }

  static String _convertToWords(int number) {
    if (number == 0) return 'Zero';

    // Handle crores
    if (number >= 10000000) {
      final crores = number ~/ 10000000;
      final remainder = number % 10000000;
      String result = '${_convertHundreds(crores)} Crore';
      if (remainder > 0) {
        result += ' ${_convertToWords(remainder)}';
      }
      return result;
    }

    // Handle lakhs
    if (number >= 100000) {
      final lakhs = number ~/ 100000;
      final remainder = number % 100000;
      String result = '${_convertHundreds(lakhs)} Lakh';
      if (remainder > 0) {
        result += ' ${_convertToWords(remainder)}';
      }
      return result;
    }

    // Handle thousands
    if (number >= 1000) {
      final thousands = number ~/ 1000;
      final remainder = number % 1000;
      String result = '${_convertHundreds(thousands)} Thousand';
      if (remainder > 0) {
        result += ' ${_convertHundreds(remainder)}';
      }
      return result;
    }

    return _convertHundreds(number);
  }

  static String _convertHundreds(int number) {
    // Ensure number is within valid range (0-999)
    // If larger, recursively convert
    if (number >= 1000) {
      final thousands = number ~/ 1000;
      final remainder = number % 1000;
      String result = '${_convertHundreds(thousands)} Thousand';
      if (remainder > 0) {
        result += ' ${_convertHundreds(remainder)}';
      }
      return result;
    }

    String result = '';

    // Hundreds
    if (number >= 100) {
      final hundreds = number ~/ 100;
      final onesWord = _safeGetOnes(hundreds);
      if (onesWord.isNotEmpty) {
        result += '$onesWord Hundred';
      } else {
        // Fallback for invalid hundreds value - try to convert recursively
        result += '${_convertHundreds(hundreds)} Hundred';
      }
      final remainder = number % 100;
      if (remainder > 0) {
        result += ' and ';
      } else {
        return result;
      }
      number = remainder;
    }

    // Tens and ones
    if (number >= 20) {
      final tensPlace = number ~/ 10;
      final tensWord = _safeGetTens(tensPlace);
      if (tensWord.isNotEmpty) {
        result += tensWord;
      }
      final onesPlace = number % 10;
      if (onesPlace > 0) {
        final onesWord = _safeGetOnes(onesPlace);
        if (onesWord.isNotEmpty) {
          result += ' $onesWord';
        }
      }
    } else if (number > 0) {
      final onesWord = _safeGetOnes(number);
      if (onesWord.isNotEmpty) {
        result += onesWord;
      } else {
        // Fallback for invalid number
        result += 'Number';
      }
    }

    return result.trim();
  }
}

