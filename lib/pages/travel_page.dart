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
  Completer<GoogleMapController> _mapsController = Completer();
  List<LatLng> _polylineCoordinates = <LatLng>[];
  List<LatLng> _locations = <LatLng>[];
  LatLng _startUserPosition = LatLng(0, 0);
  location.LocationData? _currentPosition;
  Set<Marker> _markers = {};
  @override
  void initState() {
    super.initState();
    _getStartingPosition();
    _getPlacesfromPlaceID(widget.destinationsID);
    _getCurrentLocation();
  }

  void _getStartingPosition() {
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((position) {
      setState(() {
        _startUserPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  void _getCurrentLocation() async {
    // Something wrong here with animateCamera
    // FIXME: here
    location.Location currentLocation = location.Location();
    currentLocation.getLocation().then((position) {
      _currentPosition = position;
    });
    GoogleMapController mapsController = await _mapsController.future;
    currentLocation.onLocationChanged.listen((newLocation) {
      _currentPosition = newLocation;
      mapsController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              zoom: 17.5,
              target: LatLng(newLocation.latitude!, newLocation.longitude!))));
    });
  }

  /// Sets the [_locations] variable to the geographical coordinates
  /// of all the places ID given to the widget
  void _getPlacesfromPlaceID(List<String> destinationsID) {
    String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] as String;

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
          print("PRIMA: ${_locations}");
        });
      });
    }).toList();

    Future.wait(futures).then((_) {
      _getPolylinePoints();
    });
  }

  // There is a limit on googleMaps destinations (iirc it's 25?) but
  // I don't think that we will ever have more than 25 destinations to calculate
  // but as a note leave this comment here.
  void _getPolylinePoints() {
    final String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] as String;
    PolylinePoints points = PolylinePoints();
    print("DOPO: ${_locations}");
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
            body: _currentPosition != null
                ? GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: _startUserPosition, zoom: 17.5),
                    markers: _markers,
                    onMapCreated: (mapController) {
                      _mapsController = Completer();
                      _mapsController.complete(mapController);
                    },
                    polylines: {
                      Polyline(
                          polylineId: const PolylineId("travel_route"),
                          points: _polylineCoordinates,
                          color: const Color(0xABCDEF),
                          width: 6)
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true)
                : const Center(
                    child: const Text("The page is loading, please wait..."),
                  )));
  }

  @override
  void dispose() {
    // Found this on a stackOverflow thread, hope it works.
    _mapsController = Completer();
    super.dispose();
  }
}
