class LocationData {
  final String name;
  final String nameEn;
  final List<LocationData>? states;
  final List<String>? cities;

  const LocationData({
    required this.name,
    required this.nameEn,
    this.states,
    this.cities,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      name: (json['name'] as String?) ?? '',
      nameEn: (json['name_en'] as String?) ?? '',
      states: (json['states'] as List<dynamic>?)
          ?.map((state) => LocationData.fromJson(state as Map<String, dynamic>))
          .toList(),
      cities: (json['cities'] as List<dynamic>?)
          ?.map((city) => city.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'name_en': nameEn,
      'states': states?.map((state) => state.toJson()).toList(),
      'cities': cities,
    };
  }
}
