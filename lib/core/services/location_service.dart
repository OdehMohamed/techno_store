import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:techno_store/core/models/location_data.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  LocationService._();

  List<LocationData>? _countries;

  /// Load locations data from JSON file
  Future<void> loadLocations() async {
    if (_countries != null) return; // Already loaded

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/locations.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> countriesJson = jsonData['countries'] as List;

      _countries = countriesJson
          .map((country) => LocationData.fromJson(country as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load locations data: $e');
    }
  }

  /// Get all countries
  List<String> getCountries() {
    return _countries?.map((c) => c.name).toList() ?? [];
  }

  /// Get states for a specific country
  List<String> getStates(String countryName) {
    final country = _countries?.firstWhere(
      (c) => c.name == countryName,
      orElse: () => LocationData(name: '', nameEn: ''),
    );
    return country?.states?.map((s) => s.name).toList() ?? [];
  }

  /// Get cities for a specific state
  List<String> getCities(String countryName, String stateName) {
    final country = _countries?.firstWhere(
      (c) => c.name == countryName,
      orElse: () => LocationData(name: '', nameEn: ''),
    );
    final state = country?.states?.firstWhere(
      (s) => s.name == stateName,
      orElse: () => LocationData(name: '', nameEn: ''),
    );
    return state?.cities ?? [];
  }

  /// Clear cached data (useful for testing or reload)
  void clearCache() {
    _countries = null;
  }
}
