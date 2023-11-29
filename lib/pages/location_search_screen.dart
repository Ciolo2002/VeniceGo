import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:venice_go/pages/google_maps.dart';
import '../locations.dart' as locations;
//TODO introdurre limitazioni per tipo di luogo (ristoranti, monumenti, musei etc.), potenzialmente modificabili dall'utente

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final Map<String, String> _suggestions = {};
  String _filter = '';
  Timer? _userInputTimer;
  _setFilter(String filter) {
    setState(() {
      _filter = filter;
    });
  }

  /// Uses the [userInput] String parameter to obtain a list of places from Google Maps
  /// Places API.
  Future<dynamic> _getMarkers(String userInput) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] as String;
    final locations.LatLng veniceGeoCoords =
        locations.LatLng(lat: 45.4371908, lng: 12.3345898);
    // Waits 500ms before calling the API, if the user has not typed anything else.

    // API call
    String url = 'https://places.googleapis.com/v1/places:searchText';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': 'places',
    };
    String body =
        '{"textQuery" : "$userInput", "locationBias" : { "circle": { "center": { "latitude" : ${veniceGeoCoords.lat}, "longitude" : ${veniceGeoCoords.lng} }, "radius": 10000}  }} ';

    http.Response response =
        await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode != 200) {
      print(response.body);
      throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
    }
    return json.decode(response.body);
  }

  Future<void> getMarkers(String userInput) async {
    if (_userInputTimer?.isActive ?? false) {
      _userInputTimer?.cancel();
    } else {
      _userInputTimer = Timer(const Duration(milliseconds: 500), () async {
        final mapsJSON = await _getMarkers(userInput);
        print("Here: $mapsJSON");
        // TODO: setState _suggestions and update build method
      });
    }
  }

  // Future<void> fetchSuggestions(String input) async {
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       setState(() {
  //         _suggestions =
  //             List<String>.from(data['predictions'].map((prediction) {
  //           String description = prediction['description'] as String;
  //           return _parseMainName(description);
  //         }));
  //         _suggestionsId = List<String>.from(
  //             data['predictions'].map((prediction) => prediction['place_id']));
  //       });
  //     }
  //   });
  // }

  //   String _parseMainName(String description) {
  //     List<String> parts = description.split(',');
  //     return parts.isNotEmpty ? parts[0] : description;
  //   }

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
              onChanged: (input) {
                getMarkers(input);
              },
              decoration: const InputDecoration(
                labelText: 'Search for a location',
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    // TODO: Fix porcata di copilot
                    title: const Text("CIAO"),
                    onTap: () {
                      // Changes to Google Maps page if result is selected.
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GoogleMaps()));
                      // https://stackoverflow.com/questions/50818770/passing-data-to-a-stateful-widget-in-flutter
                      // come passare parametri ad uno stateful widget
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

  @override
  void dispose() {
    _userInputTimer?.cancel();
    super.dispose();
  }
}
