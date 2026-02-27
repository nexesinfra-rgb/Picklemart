/// Store company information for bill generation
class StoreCompanyInfo {
  static const String name = 'PICKLE MART';
  static const String address = 'D.No.25-4-28, 1st Floor, KSR st, R.R.Pet, Eluru-2.';
  static const String phone = '9676494040';
  static const String email = 'picklemarts@gmail.com';
  static const String city = 'Eluru';
  static const String state = '37-Andhra Pradesh';
  static const String pincode = '534002';
  static const String fssaiNo = '20122111000068';
  static const String gst = '';

  /// Get company info as a map for bill data
  static Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'city': city,
      'state': state,
      'pincode': pincode,
      'fssai_no': fssaiNo,
    };
  }
}

