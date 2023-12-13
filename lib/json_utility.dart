import "../locations.dart" as locations;

import 'package:google_maps_flutter/google_maps_flutter.dart'
    show Marker, MarkerId, InfoWindow, LatLng;
// These classes are used to parse the JSON response from Google Maps Places API, and are not used anywhere else in the app.
// They are included here to make the code more readable.

class DisplayName {
  DisplayName(this.text, this.languageCode);
  DisplayName.fromJson(Map<String, dynamic> json)
      : text = json['text'] as String? ?? '',
        languageCode = json['languageCode'] as String? ?? '';
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

  static Marker toMarker(Place place) {
    try {
      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.location.lat, place.location.lng),
        infoWindow: InfoWindow(
          title: place.displayName.text,
          snippet: place.formattedAddress,
        ),
      );
    } catch (e) {
      throw Exception("Error while converting Place to Marker: $e");
    }
  }
}

class PlaceDetails {
  PlaceDetails({
    required this.id,
    required this.displayName,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      id: json['id'] as String,
      displayName: DisplayName.fromJson(json['displayName']),
    );
  }

  final String id;
  final DisplayName displayName;
}
