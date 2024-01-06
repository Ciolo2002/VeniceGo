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
  List<LatLng> _polylineCoordinates = <LatLng>[];
  List<LatLng> _locations = <LatLng>[];
  LatLng _startUserPosition = LatLng(0, 0);
  Set<Marker> _markers = {};
  @override
  void initState() {
    super.initState();
    _getStartingPosition();
    _getPlacesfromPlaceID(widget.destinationsID);
    _getCurrentPosition();
  }

  /// Sets the [_startUserPosition] variable to the geographical coordinates
  /// of the user's current position
  void _getStartingPosition() {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((position) {
      setState(() {
        _startUserPosition = LatLng(position.latitude, position.longitude);
        _markers.add(Marker(
            markerId: const MarkerId("start_user_position"),
            position: _startUserPosition));
      });
    });
  }

  /// Removes the old current position marker and adds the new one
  /// to the [_markers] set.
  void _getCurrentPosition() {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((position) {
      setState(() {
        _markers.removeWhere(
            (element) => element.markerId.value == "current_position");
        _markers.add(Marker(
            markerId: const MarkerId("current_position"),
            position: LatLng(position.latitude, position.longitude)));
      });
    });
  }

  /// Sets the [_locations] variable to the geographical coordinates
  /// of all the places ID given to the widget
  void _getPlacesfromPlaceID(List<String> destinationsID) {
    String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] as String;
    // Copilot magic here
    // But if i understood correctly what copilot is doing
    // it's just a loop that wait for all http request to finish
    // and parse the json.
    List<Future> futures = destinationsID.map((destination) {
      String url =
          "https://places.googleapis.com/v1/places/${destination}?fields=name,id,formattedAddress,location,displayName&key=${apiKey}";
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
  /// of the route from the user's current position to the destinations in the
  /// [_locations] variable.
  void _getPolylinePoints() {
    // There is a limit on googleMaps destinations (iirc it's 25?) but
    // I don't think that we will ever have more than 25 destinations to calculate
    // but as a note leave this comment here.
    final String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] as String;
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
        "latitude": ${_startUserPosition.latitude},
        "longitude": ${_startUserPosition.longitude}
      }
    }
  },
  "destination":{
    "location":{
      "latLng":{
        "latitude": ${_locations[0].latitude},
        "longitude": ${_locations[0].longitude} 
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
      res.forEach((point) {
        setState(() {
          _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });
      });
    });
    // I know that it's not the best way to do it but I don't have
    // enough time to do it in a better way.
    // I will just copy and paste the code above and change the destination
    // and the origin.
    // TODO: refactor this code
    for (int i = 0; i < _locations.length - 1; ++i) {
      body = '''
    {
  "origin":{
    "location":{
      "latLng":{
        "latitude": ${_locations[i].latitude},
        "longitude": ${_locations[i].longitude}
      }
    }
  },
  "destination":{
    "location":{
      "latLng":{
        "latitude": ${_locations[i + 1].latitude},
        "longitude": ${_locations[i + 1].longitude} 
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
        res.forEach((point) {
          setState(() {
            _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            body: GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _startUserPosition, zoom: 17.5),
                markers: _markers,
                onMapCreated: (mapController) {
                  _mapsController = mapController;
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

  @override
  void dispose() {
    _mapsController.dispose();
    super.dispose();
  }
}
