import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
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
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];
  List<String> _suggestionsId = [];
  String? _sessionToken;
  Timer? _debounce;
  String _selectedFilter = '';
  String generateSessionToken() {
    Uuid uuid = const Uuid();
    return uuid.v4();
  }

  Future<void> fetchSuggestions(String input) async {
    if (_debounce != null && _debounce!.isActive) {
      _debounce!.cancel();
    }

    _sessionToken ??= generateSessionToken();

    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] as String;
    String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input';

    // Coordinates for Venice, Italy
    final locations.LatLng veniceGeoCoords =
        locations.LatLng(lat: 45.4371908, lng: 12.3345898);

    const int radius = 10000; //decide reasonable restriction

    if (_selectedFilter.isNotEmpty) {
      url += '&types=$_selectedFilter';
    }

    url +=
        '&components=country:IT&locationrestriction=circle:$radius@veniceLng${veniceGeoCoords.lat},${veniceGeoCoords.lng}&key=$apiKey&sessiontoken=$_sessionToken'; // Adjust parameters

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final http.Response response = await http.get(Uri.parse(url));

      print(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _suggestions =
              List<String>.from(data['predictions'].map((prediction) {
            String description = prediction['description'] as String;
            return _parseMainName(description);
          }));
          _suggestionsId = List<String>.from(
              data['predictions'].map((prediction) => prediction['place_id']));
        });
      }
    });
  }

  String _parseMainName(String description) {
    List<String> parts = description.split(',');
    return parts.isNotEmpty ? parts[0] : description;
  }

  void setSelectedFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  void dispose() {
    // Basically, C++'s destructor call.
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
                    onPressed: () => setSelectedFilter('food'),
                    child: const Text('F'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setSelectedFilter('museum'),
                    child: const Text('M'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setSelectedFilter('night_club'),
                    child: const Text('N'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setSelectedFilter('park'),
                    child: const Text('P'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setSelectedFilter('supermarket'),
                    child: const Text('S'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setSelectedFilter(''),
                    child: const Text('E'),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _searchController,
              onChanged: (input) {
                fetchSuggestions(input);
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
                    title: Text(_suggestions[index]),
                    onTap: () {
                      // Handle selection
                      // TODO: https://docs.flutter.dev/cookbook/navigation/navigation-basics
                      // Quel link spiega come navigare tra le pagine
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GoogleMaps()));
                      // https://stackoverflow.com/questions/50818770/passing-data-to-a-stateful-widget-in-flutter
                      // come passare parametri ad uno stateful widget
                      print('Selected ID: ${_suggestionsId[index]}');
                      print('Selected: ${_suggestions[index]}');
                      _sessionToken = null;
                      // trovare il modo di eliminare le suggestion dallo schermo dopo la selezione
                      _suggestions.clear();
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
