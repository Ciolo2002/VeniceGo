//TODO COMMANDI DA RUNNARE PER GOOGLE MAPS:
//flutter  pub add google_maps_flutter
//flutter  pub add http
// flutter  pub add json_serializable
//flutter  pub add --dev build_runner
//flutter  pub run build_runner build --delete-conflicting-outputs //POTREBBE NON SERVIRE, GENERA IL FILE locations.g.dart (che ho già fatto io)
//GOOGLE MAP ""S CONSOLE: https://console.cloud.google.com/google/maps-apis/home?project=venicego ACCEDETE CON LA MAIL DELL'UNIVERSITA'

//import 'dart:html';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../locations.dart' as locations;
import '../json_utility.dart' show Place;

class GoogleMaps extends StatefulWidget {
  final Set<Marker>? markers;
  const GoogleMaps({super.key, this.markers});

  @override
  State<GoogleMaps> createState() => _MyGoogleMapsState();
}

class _MyGoogleMapsState extends State<GoogleMaps> {
  late GoogleMapController mapController;
  List<Place> _suggestions = [];
  bool showListView = false;
  String _filter = '';
  final locations.LatLng veniceGeoCoords =
      locations.LatLng(lat: 45.4371908, lng: 12.3345898);
  final LatLng _veniceGeoCoords = const LatLng(45.4371908, 12.3345898);

  _setFilter(String filter) {
    setState(() {
      _filter = filter;
    });
  }

  /// When the map is created, we add some default markers if we do not have any.
  Future<void> _onMapCreated(GoogleMapController controller) async {
    if (widget.markers != null && widget.markers!.isEmpty) {
      final locations.Locations googleOffices =
          await locations.getGoogleOffices();
      setState(() {
        for (final office in googleOffices.offices) {
          final marker = Marker(
            markerId: MarkerId(office.name),
            position: LatLng(office.lat, office.lng),
            infoWindow: InfoWindow(
              title: office.name,
              snippet: office.address,
            ),
          );
          widget.markers!.add(marker);
        }
      });
    }
  }

  /// Uses the [userInput] String parameter to obtain a list of places from Google Maps
  /// Places API.
  Future<dynamic> _getMarkers(String userInput) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] as String;

    // API call section
    String url = 'https://places.googleapis.com/v1/places:searchText';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask':
          'places.displayName,places.formattedAddress,places.location,places.id,places.name',
    };
    // TODO: find how much i can stretch the radius before getting garbage (results from random places)
    String body =
        '{"textQuery" : "$userInput", "locationBias" : { "circle": { "center": { "latitude" : ${veniceGeoCoords.lat}, "longitude" : ${veniceGeoCoords.lng} },  "radius": 500}}} ';

    http.Response response =
        await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
    }
    return json.decode(response.body);
  }

  /// Uses the [userInput] String parameter to obtain a list of places from Google Maps
  Future<void> getMarkers(String userInput) async {
    final dynamic jsonMarkers = await _getMarkers(userInput);
    List<dynamic> placesList = jsonMarkers['places'];
    setState(() {
      _suggestions =
          List<Place>.from(placesList.map((place) => Place.fromJson(place)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Scaffold(
        body: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onSubmitted: (input) {
                      getMarkers(input);
                      setState(() {
                        showListView = true;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Search for a location',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      showListView = !showListView;
                    });
                  },
                  icon: Icon(Icons.remove),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setFilter('food'),
                    child: const Text('F'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setFilter('museum'),
                    child: const Text('M'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setFilter('night_club'),
                    child: const Text('N'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setFilter('park'),
                    child: const Text('P'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setFilter('supermarket'),
                    child: const Text('S'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _setFilter(''),
                    child: const Text('E'),
                  ),
                ),
              ],
            ),
            if (showListView)
              Expanded(
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_suggestions[index].displayName.text),
                      onTap: () {
                        Set<Marker> markers = {};
                        markers.add(Place.toMarker(_suggestions[index]));
                        setState(() {
                          showListView = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GoogleMap(
                              markers: markers,
                              initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                      veniceGeoCoords.lat, veniceGeoCoords.lng),
                                  zoom: 13.0),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            Expanded(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  //target: LatLng(0,0), //COORDINATE DI TEST,
                  target: _veniceGeoCoords, //COORDINATE DI VENEZIA
                  zoom: 13.0, // ZOOM DI VENEZIA
                  //zoom: 2.0,// ZOOM DI TEST
                ),
                markers: widget.markers ?? {},
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
