class LocationData {
  final String name;
  final String nameEn;
  final List<String>? cities;
  final List<LocationData>? states;

  LocationData({
    required this.name,
    required this.nameEn,
    this.cities,
    this.states,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      name: json['name'] as String,
      nameEn: json['name_en'] as String,
      cities: json['cities'] != null
          ? List<String>.from(json['cities'] as List)
          : null,
      states: json['states'] != null
          ? (json['states'] as List)
              .map((state) => LocationData.fromJson(state as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'name_en': nameEn,
      if (cities != null) 'cities': cities,
      if (states != null) 'states': states?.map((s) => s.toJson()).toList(),
    };
  }
}
