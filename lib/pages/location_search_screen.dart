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
  final TextEditingController _textChangeController = TextEditingController();
  final Map<String, String> _suggestions = {};
  late String _filter;
  String _previousUserInput = '';
  Timer? _userInputTimer;
  _setFilter(String filter) {
    setState(() {
      _filter = filter;
    });
  }

  /// Uses the [userInput] String parameter to obtain a list of places from Google Maps
  /// Places API.
  /// The method returns the decoded json data if the user has not typed any input after
  /// 500ms of inactivity
  Future<dynamic> _getMarkers(String userInput) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] as String;
    final locations.LatLng veniceGeoCoords =
        locations.LatLng(lat: 45.4371908, lng: 12.3345898);
    // Delay execution if user input has not changed
    if (userInput == _previousUserInput) {
      if (_userInputTimer != null && _userInputTimer!.isActive) {
        _userInputTimer!.cancel();
      }
      _userInputTimer = Timer(const Duration(milliseconds: 500), () {
        _getMarkers(userInput);
      });
      return null;
    }
    _previousUserInput = userInput;
    String url = 'https://places.googleapis.com/v1/places:searchText';
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      // Change this to add parameters
      'X-Goog-FieldMask': 'places.id, places.displayName, places.location',
    };
    String body = json.encode({
      "locationBias": {
        "circle": {
          "center": {
            "latitude": veniceGeoCoords.lat,
            "longitude": veniceGeoCoords.lng,
          },
          "radiusMeters": 10000, // 10 Km
        },
      },
      'textQuery': userInput,
      if (_filter.isNotEmpty) 'includedType': _filter,
    });
    http.Response response =
        await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
    }
    return json.decode(response.body);
  }

  Future<void> getMarkers(String userInput) async {
    // Modify this method to use the _getMarkers() method and check for null values
    // before setting the _suggestions state variable.
    final data = await _getMarkers(userInput);
    print(data);
    if (data != null) {}
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
              controller: _textChangeController,
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
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    // TODO: Fix porcata di copilot
                    title: Text(_suggestions.keys.elementAt(index)),
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
}
