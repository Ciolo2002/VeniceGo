import "dart:async";
import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart" show dotenv;
import "package:flutter_polyline_points/flutter_polyline_points.dart";
import "package:geolocator/geolocator.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:http/http.dart" as http;
import "package:venice_go/json_utility.dart" show Place;
import "../json_utility.dart" as utility show Polyline;

class TravelPage extends StatefulWidget {
  const TravelPage({super.key, required this.destinationsID});
  final List<String> destinationsID;
  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  late GoogleMapController _mapsController;
  final List<LatLng> _polylineCoordinates = <LatLng>[];
  final List<LatLng> _locations = <LatLng>[];
  late LatLng _currentUserPosition = LatLng(0, 0);
  final Set<Marker> _markers = {};
  late StreamSubscription<Position> _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
  }

  /// Sets the [_currentUserPosition] variable to the geographical coordinates
  /// of the user's current position
  void _getStartingPosition() {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((position) {
      setState(() {
        _currentUserPosition = LatLng(position.latitude, position.longitude);
        _markers.add(Marker(
            markerId: const MarkerId("start_user_position"),
            position: _currentUserPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen)));
      });
    });

    _mapsController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentUserPosition, zoom: 17.5)));
    _getPlacesfromPlaceID(widget.destinationsID);
  }

  void _updateCurrentPosition(Position pos) {
    _markers
        .removeWhere((element) => element.markerId.value == "current_position");
    _markers.add(Marker(
        markerId: const MarkerId("current_position"),
        position: LatLng(pos.latitude, pos.longitude),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)));
  }

  /// Removes the old current position marker and adds the new one
  /// to the [_markers] set.
  void _getCurrentPosition() {
    // Adds a listener for the current position
    // so that the marker will update its position
    // when the user moves.
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen((position) {
      setState(() {
        _updateCurrentPosition(position);
      });
    });
    // Updates the camera position to the new current position
    // when the user moves.
    _positionStreamSubscription.onData((position) {
      _mapsController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 17.5)));
      setState(() {
        _updateCurrentPosition(position);
        if (_currentUserPosition.latitude != position.latitude &&
            _currentUserPosition.longitude != position.longitude) {
          _currentUserPosition = LatLng(position.latitude, position.longitude);
          _getPolylinePoints();
        }
      });
    });
  }

  /// Sets the [_locations] variable to the geographical coordinates
  /// of all the places ID given to the widget
  void _getPlacesfromPlaceID(List<String> destinationsID) {
    String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] as String;
    // Copilot magic here
    // But if i understood correctly what copilot is doing
    // it's just a loop that waits for all http requests to finish
    // and then parse the resulting json.
    List<Future> futures = destinationsID.map((destination) {
      String url =
          "https://places.googleapis.com/v1/places/$destination?fields=name,id,formattedAddress,location,displayName&key=$apiKey";
      return http.get(Uri.parse(url)).then((response) {
        if (response.statusCode != 200) {
          throw Exception(
              "Error ${response.statusCode}: ${response.reasonPhrase}");
        }

        dynamic tempJson = json.decode(response.body);
        Place place = Place.fromJson(tempJson);
        _markers.add(Place.toMarker(place));
        setState(() {
          _locations.add(LatLng(place.location.lat, place.location.lng));
        });
      });
    }).toList();

    Future.wait(futures).then((_) {
      _getPolylinePoints();
    });
  }

  /// Sets the [_polylineCoordinates] variable to the geographical coordinates
  /// of the route from the source [src] parameter to the destination [dest]
  /// parameter.
  void _getPolylinePointsBetweenPlaces(String apiKey, LatLng src, LatLng dest) {
    String url = 'https://routes.googleapis.com/directions/v2:computeRoutes';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask':
          'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
    };
    // travelMode: TRANSIT per i mezzi pubblici
    String body = '''
    {
  "origin":{
    "location":{
      "latLng":{
        "latitude": ${src.latitude},
        "longitude": ${src.longitude}
      }
    }
  },
  "destination":{
    "location":{
      "latLng":{
        "latitude": ${dest.latitude},
        "longitude": ${dest.longitude} 
      }
    }
  },
    "travelMode": "WALK",
    "units": "METRIC",
    }
    ''';
    http.post(Uri.parse(url), headers: headers, body: body).then((response) {
      List<dynamic> temp = json.decode(response.body)["routes"];
      utility.Polyline polylineJSON = utility.Polyline.fromJson(temp[0]);
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> res =
          polylinePoints.decodePolyline(polylineJSON.encodedPolyline);
      for (var point in res) {
        setState(() {
          _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });
      }
    });
  }

  /// Sets the [_polylineCoordinates] variable to the geographical coordinates
  /// of the route from the user's current position to the destinations in the
  /// [_locations] variable.
  void _getPolylinePoints() {
    // There is a limit on googleMaps destinations (iirc it's 25?) but
    // I don't think that we will ever have more than 25 destinations to calculate
    // but as a note leave this comment here.
    final String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] as String;
    // This is a workaround because i could have added _currentUserPosition
    // to the _locations list but i wanted to keep it separate.

    if (_polylineCoordinates.isNotEmpty) {
      _polylineCoordinates.clear();
    }

    _getPolylinePointsBetweenPlaces(
        apiKey, _currentUserPosition, _locations[0]);

    for (int i = 0; i < _locations.length - 1; i++) {
      _getPolylinePointsBetweenPlaces(apiKey, _locations[i], _locations[i + 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            body: GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _currentUserPosition, zoom: 17.5),
                markers: _markers,
                onMapCreated: (mapController) {
                  _onMapCreated(mapController);
                },
                polylines: {
                  Polyline(
                      polylineId: const PolylineId("travel_route"),
                      points: _polylineCoordinates,
                      color: Colors.purple,
                      width: 6)
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true)));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapsController = controller;
    _getStartingPosition();
    _getCurrentPosition();
  }

  @override
  void dispose() {
    _mapsController.dispose();
    _positionStreamSubscription.cancel();
    super.dispose();
  }
}
