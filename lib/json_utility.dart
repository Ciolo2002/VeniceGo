import "../locations.dart" as locations;

// These classes are used to parse the JSON response from Google Maps Places API, and are not used anywhere else in the app.
// They are included here to make the code more readable.

class DisplayName {
  DisplayName(this.text, this.languageCode);
  DisplayName.fromJson(Map<String, dynamic> json)
      : text = json['text'] as String,
        languageCode = json['languageCode'] as String;
  final String text;
  final String languageCode;
}

class Place {
  Place({
    required this.name,
    required this.id,
    required this.formattedAddress,
    required this.location,
    required this.displayName,
  });
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['name'],
      id: json['id'],
      formattedAddress: json['formattedAddress'],
      location: locations.LatLng.fromJson(json['location']),
      displayName: DisplayName.fromJson(json['displayName']),
    );
  }
  final String name;
  final String id;
  final String formattedAddress;
  final DisplayName displayName;
  final locations.LatLng location;
}
