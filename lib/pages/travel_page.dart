import "dart:async";
import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart" show dotenv;
import "package:flutter_polyline_points/flutter_polyline_points.dart";
import "package:geolocator/geolocator.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:http/http.dart" as http;
import "package:venice_go/json_utility.dart" show Place;

class TravelPage extends StatefulWidget {
  const TravelPage({super.key, required this.destinationsID});
  final List<String> destinationsID;
  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  final Completer<GoogleMapController> _mapsController = Completer();
  late List<LatLng> _locations;
  late final LatLng _currentUserPosition;
  late Set<Marker> _markers;
  @override
  void initState() async {
    super.initState();
    _currentUserPosition = await _getCurrentPosition();
    _locations = await _getPlacesfromPlaceID(widget.destinationsID);
  }

  Future<LatLng> _getCurrentPosition() async {
    Position currentUserLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return LatLng(currentUserLocation.latitude, currentUserLocation.longitude);
  }

  /// Sets the [_locations] variable to the geographical coordinates
  /// of all the places ID given to the widget
  Future<List<LatLng>> _getPlacesfromPlaceID(
      List<String> destinationsID) async {
    String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] as String;
    List<LatLng> res = <LatLng>[];
    destinationsID.forEach((destinationID) async {
      // Actually we only need the location field but since we already have
      // a class for Places, we can reuse that.
      String url =
          "https://places.googleapis.com/v1/places/${destinationID}?fields=name,id,formattedAddress,location,displayName&key=${apiKey}";
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception(
            "Error ${response.statusCode}: ${response.reasonPhrase}");
      }
      // Conversion from JSON to Dart objects
      dynamic tempJson = json.decode(response.body)["places"];
      Place place = Place.fromJson(tempJson);
      _markers.add(Place.toMarker(place));
      res.add(LatLng(place.location.lat, place.location.lng));
    });
    return res;
  }

  // There is a limit on googleMaps destinations (iirc it's 25?) but
  // I don't think that we will have more than 25 destinations to calculate
  Future<List<LatLng>> _getPolylinePoints() async {
    PolylinePoints points = PolylinePoints();
    List<LatLng> coords = <LatLng>[];
    PolylineResult res = await points.getRouteBetweenCoordinates(
      dotenv.env["GOOGLE_MAPS_API_KEY"] as String,
      PointLatLng(
          _currentUserPosition.latitude, _currentUserPosition.longitude),
    );
    return <LatLng>[];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            body: GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _currentUserPosition, zoom: 14.0),
                markers: _markers,
                onMapCreated: (mapController) {
                  _mapsController.complete(mapController);
                })));
  }
}
