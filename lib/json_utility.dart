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
    required this.photos,
    required this.address,
    required this.reviews,
    required this.openingHours,
    required this.rating,
    required this.nationalPhoneNumber,
    required this.websiteUri,
    required this.editorialSummary,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    List<Photo> photos = <Photo>[];
    if (json['photos'] != null) {
      photos = (json['photos'] as List<dynamic>)
          .map((photoJson) => Photo.fromJson(photoJson))
          .toList();
    }

    List<Review> reviews = <Review>[];
    if (json['reviews'] != null) {
      reviews = (json['reviews'] as List<dynamic>)
          .map((reviewJson) => Review.fromJson(reviewJson))
          .toList();
    }

    final openingHoursJson = json['currentOpeningHours'];
    bool openNow = openingHoursJson?['openNow'] ?? false;
    List<String> weekdayDescriptions = [];
    if (openingHoursJson != null) {
      final weekdayDescriptionsJson = openingHoursJson['weekdayDescriptions'];
      if (weekdayDescriptionsJson != null &&
          weekdayDescriptionsJson is List<dynamic>) {
        weekdayDescriptions = weekdayDescriptionsJson.cast<String>();
      }
    }
    final openingHours = OpeningHours(
      weekdayDescriptions: weekdayDescriptions,
      openNow: openNow,
    );

    final String nationalPhoneNumber =
        json['nationalPhoneNumber'] as String? ?? '';
    final String websiteUri = json['websiteUri'] as String? ?? '';
    String editorialSummary = '';

    if (json['editorialSummary'] != null) {
      editorialSummary = json['editorialSummary']['text'] as String? ?? '';
    }

    return PlaceDetails(
      id: json['id'] as String,
      displayName: DisplayName.fromJson(json['displayName']),
      photos: photos,
      address: json['shortFormattedAddress'] as String,
      reviews: reviews,
      openingHours: openingHours,
      rating: json['rating'] != null
          ? (json['rating'] is int
              ? (json['rating'] as int).toDouble()
              : json['rating'] as double)
          : 0.0,
      nationalPhoneNumber: nationalPhoneNumber,
      websiteUri: websiteUri,
      editorialSummary: editorialSummary,
    );
  }

  final String id;
  final DisplayName displayName;
  final List<Photo> photos;
  final String address;
  final List<Review> reviews;
  final OpeningHours openingHours;
  final double rating;
  final String nationalPhoneNumber;
  final String websiteUri;
  final String editorialSummary;
}

class Review {
  Review({
    required this.authorName,
    required this.rating,
    required this.text,
    required this.publishTime,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    //String text = '';
    //if (json['text'] != null) {
    //  text = json['text']['text'];
    //}

    return Review(
      authorName: json['authorAttribution']['displayName'] as String,
      rating: json['rating'] as int,
      text:
          (json['text'] == null ? '' : (json['text']['text'] ?? '')) as String,
      publishTime: json['relativePublishTimeDescription'] as String,
    );
  }

  final String authorName;
  final int rating;
  final String text;
  final String publishTime;
}

class Photo {
  Photo({
    required this.name,
    required this.widthPx,
    required this.heightPx,
    required this.authorAttributions,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      name: json['name'] as String,
      widthPx: json['widthPx'] as int,
      heightPx: json['heightPx'] as int,
      authorAttributions: (json['authorAttributions'] as List<dynamic>)
          .map((attributionJson) => AuthorAttribution.fromJson(attributionJson))
          .toList(),
      // Parse other fields as needed
    );
  }

  final String name;
  final int widthPx;
  final int heightPx;
  final List<AuthorAttribution> authorAttributions;
}

class AuthorAttribution {
  AuthorAttribution({
    required this.displayName,
    required this.uri,
    required this.photoUri,
  });

  factory AuthorAttribution.fromJson(Map<String, dynamic> json) {
    return AuthorAttribution(
      displayName: json['displayName'] as String,
      uri: json['uri'] as String,
      photoUri: json['photoUri'] as String,
    );
  }

  final String displayName;
  final String uri;
  final String photoUri;
}

class OpeningHours {
  OpeningHours({
    required this.weekdayDescriptions,
    required this.openNow,
  });

  final List<String> weekdayDescriptions;
  final bool openNow;
}

class Polyline {
  Polyline(
      {required this.distanceMeters,
      required this.encodedPolyline,
      required this.duration});

  factory Polyline.fromJson(Map<String, dynamic> json) {
    return Polyline(
      distanceMeters: json['distanceMeters'] as int,
      encodedPolyline: json['polyline']['encodedPolyline'] as String,
      duration: json['duration'] as String,
    );
  }

  final int distanceMeters;
  final String encodedPolyline;
  final String duration;
}
