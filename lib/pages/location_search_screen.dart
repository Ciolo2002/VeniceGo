import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../locations.dart' as locations;
import "../json_utility.dart";
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show CameraPosition, GoogleMap, LatLng, Marker;

//TODO introdurre limitazioni per tipo di luogo (ristoranti, monumenti, musei etc.), potenzialmente modificabili dall'utente
class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  List<Place> _suggestions = [];
  String _filter = '';
  final locations.LatLng veniceGeoCoords =
      locations.LatLng(lat: 45.4371908, lng: 12.3345898);

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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
            TextField(
              onSubmitted: (input) {
                getMarkers(input);
              },
              decoration: const InputDecoration(
                labelText: 'Search for a location',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_suggestions[index].displayName.text),
                    onTap: () {
                      Set<Marker> markers = {};
                      markers.add(Place.toMarker(_suggestions[index]));
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
          ],
        ),
      ),
    );
  }
}
