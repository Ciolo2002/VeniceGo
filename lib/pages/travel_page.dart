import "dart:async";
import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart" show dotenv;
import "package:flutter_polyline_points/flutter_polyline_points.dart";
import "package:geolocator/geolocator.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:http/http.dart" as http;
import "package:location/location.dart" as location;
import "package:venice_go/json_utility.dart" show Place;

class TravelPage extends StatefulWidget {
  const TravelPage({super.key, required this.destinationsID});
  final List<String> destinationsID;
  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  final Completer<GoogleMapController> _mapsController = Completer();
  late List<LatLng> _polylineCoordinates = <LatLng>[];
  late List<LatLng> _locations = <LatLng>[];
  LatLng _startUserPosition = LatLng(0, 0);
  location.LocationData? _currentPosition;
  Set<Marker> _markers = {};
  @override
  void initState() {
    _getStartingPosition();
    _getPlacesfromPlaceID(widget.destinationsID);
    _getPolylinePoints();
    _getCurrentLocation();
    super.initState();
  }

  void _getStartingPosition() {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((value) {
      _startUserPosition = LatLng(value.latitude, value.longitude);
    });

    setState(() {});
  }

  void _getCurrentLocation() async {
    location.Location _currentLocation = location.Location();
    _currentLocation.getLocation().then((position) {
      _currentPosition = position;
    });
    GoogleMapController mapsController = await _mapsController.future;
    _currentLocation.onLocationChanged.listen((newPosition) {
      _currentPosition = newPosition;
      mapsController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(newPosition.latitude!, newPosition.longitude!))));
    });
    setState(() {});
  }

  /// Sets the [_locations] variable to the geographical coordinates
  /// of all the places ID given to the widget
  void _getPlacesfromPlaceID(List<String> destinationsID) {
    String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] as String;
    destinationsID.forEach((destination) {
      // Actually we only need the location field but since we already have
      // a class for Places, we can reuse that.
      String url =
          "https://places.googleapis.com/v1/places/${destination}?fields=name,id,formattedAddress,location,displayName&key=${apiKey}";
      http.get(Uri.parse(url)).then((response) {
        if (response.statusCode != 200) {
          throw Exception(
              "Error ${response.statusCode}: ${response.reasonPhrase}");
        }

        dynamic tempJson = json.decode(response.body);
        Place place = Place.fromJson(tempJson);
        _markers.add(Place.toMarker(place));
        _locations.add(LatLng(place.location.lat, place.location.lng));
      });
    });
    setState(() {});
  }

  // There is a limit on googleMaps destinations (iirc it's 25?) but
  // I don't think that we will ever have more than 25 destinations to calculate
  // but as a note leave this comment here.
  void _getPolylinePoints() {
    final String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] as String;
    PolylinePoints points = PolylinePoints();
    if (_locations.isNotEmpty) {
      points
          .getRouteBetweenCoordinates(
              apiKey,
              PointLatLng(
                  _startUserPosition.latitude, _startUserPosition.longitude),
              PointLatLng(_locations[0].latitude, _locations[0].longitude))
          .then((response) {
        response.points.forEach((point) {
          _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });
      });
    }
    for (var i = 0; i < _locations.length - 1; i++) {
      points
          .getRouteBetweenCoordinates(
              apiKey,
              PointLatLng(_locations[i].latitude, _locations[i].longitude),
              PointLatLng(
                  _locations[i + 1].latitude, _locations[i + 1].longitude))
          .then((response) {
        response.points.forEach((point) {
          _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            body: _startUserPosition != null
                ? GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: _startUserPosition, zoom: 14.0),
                    markers: _markers,
                    onMapCreated: (mapController) {
                      _mapsController.complete(mapController);
                    },
                    polylines: {
                        Polyline(
                            polylineId: const PolylineId("travel_route"),
                            points: _polylineCoordinates,
                            color: const Color(0xABCDEF),
                            width: 6)
                      })
                : const Center(
                    child: const Text(
                        "Something's wrong... please reload the app."),
                  )));
  }
}
