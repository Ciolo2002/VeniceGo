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
import 'package:venice_go/pages/details_page.dart';
import '../json_utility.dart' show Place;

class GoogleMaps extends StatefulWidget {
  const GoogleMaps({super.key});

  @override
  State<GoogleMaps> createState() => _MyGoogleMapsState();
}

class _MyGoogleMapsState extends State<GoogleMaps> {
  late GoogleMapController mapController;
  List<Place> _suggestions = [];
  bool showListView = false;
  String _filter = '';
  final LatLng _veniceGeoCoords = const LatLng(45.4371908, 12.3345898);
  final Set<Marker> _markers = {};
  _setFilter(String filter) {
    setState(() {
      _filter = filter;
    });
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
    // TODO: pretty print this... it's a mess
    String body =
        '{"textQuery" : "$userInput", "locationBias" : { "circle": { "center": { "latitude" : ${_veniceGeoCoords.latitude}, "longitude" : ${_veniceGeoCoords.longitude} },  "radius": 500}}} ';

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
    // TODO: Ottimizzare: evitare di passare da lista a set e fare tutto con un set.
    setState(() {
      _suggestions =
          List<Place>.from(placesList.map((place) => Place.fromJson(place)));
      _markers.clear();
      _markers.addAll(
          Set<Marker>.from(_suggestions.map((place) => Place.toMarker(place))));
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
                  icon: const Icon(Icons.remove),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // TODO: update _setFilter with the new API filters.
                Expanded(
                  // uso improptio del filter button per testare il Navigator push di un place ID verso la details page
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsPage(
                              placeID: 'ChIJpWw4lNCxfkcR_9t-EkZkUhg'),
                        ),
                      );
                    },
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
                        setState(() {
                          _markers.clear();
                          _markers.add(Place.toMarker(_suggestions[index]));
                          showListView = false;
                        });
                      },
                    );
                  },
                ),
              ),
            Expanded(
              child: GoogleMap(
                onMapCreated: null,
                initialCameraPosition: CameraPosition(
                  target: _veniceGeoCoords,
                  zoom: 13.0,
                ),
                markers: _markers,
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
