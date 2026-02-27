import 'location_data.dart';

class SearchResult {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String? state;
  final String? street;
  final String? houseNumber;
  final String? postcode;

  const SearchResult({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.state,
    this.street,
    this.houseNumber,
    this.postcode,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] ?? {};
    final geometry = json['geometry'] ?? {};
    final coordinates = geometry['coordinates'] as List? ?? [];
    
    return SearchResult(
      name: properties['name'] ?? '',
      displayName: _buildDisplayName(properties),
      latitude: coordinates.isNotEmpty ? coordinates[1]?.toDouble() ?? 0.0 : 0.0,
      longitude: coordinates.isNotEmpty ? coordinates[0]?.toDouble() ?? 0.0 : 0.0,
      city: properties['city'],
      country: properties['country'],
      state: properties['state'],
      street: properties['street'],
      houseNumber: properties['housenumber'],
      postcode: properties['postcode'],
    );
  }

  static String _buildDisplayName(Map<String, dynamic> properties) {
    final name = properties['name'] ?? '';
    final city = properties['city'] ?? '';
    final country = properties['country'] ?? '';
    
    if (name.isNotEmpty && city.isNotEmpty && country.isNotEmpty) {
      return '$name, $city, $country';
    } else if (name.isNotEmpty && city.isNotEmpty) {
      return '$name, $city';
    } else if (name.isNotEmpty) {
      return name;
    } else if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    } else if (city.isNotEmpty) {
      return city;
    } else {
      return 'Unknown location';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'state': state,
      'street': street,
      'houseNumber': houseNumber,
      'postcode': postcode,
    };
  }

  LocationData toLocationData() {
    return LocationData(
      latitude: latitude,
      longitude: longitude,
      address: displayName,
      city: city,
      country: country,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.name == name;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'SearchResult(name: $name, lat: $latitude, lng: $longitude)';
  }
}
