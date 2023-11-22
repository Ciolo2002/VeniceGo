import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    var uuid = const Uuid();
    return uuid.v4();
  }

  void fetchSuggestions(String input) async {
    if (_debounce != null && _debounce!.isActive) {
      _debounce!.cancel();
    }

    _sessionToken ??= generateSessionToken();

    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] as String;
    String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input';

    // Coordinates for Venice, Italy
    const double veniceLat = 45.4375;
    const double veniceLng = 12.3355;
    const int radius = 10000; //decide reaasonable restriction

    if (_selectedFilter.isNotEmpty) {
      url += '&types=$_selectedFilter';
    }

    url +=
        '&components=country:IT&locationrestriction=circle:$radius@$veniceLat,$veniceLng&key=$apiKey&sessiontoken=$_sessionToken'; // Adjust parameters

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

  void onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  void dispose() {
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
                    onPressed: () => onFilterSelected('food'),
                    child: const Text('F'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onFilterSelected('museum'),
                    child: const Text('M'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onFilterSelected('night_club'),
                    child: const Text('N'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onFilterSelected('park'),
                    child: const Text('P'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onFilterSelected('supermarket'),
                    child: const Text('S'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onFilterSelected(''),
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
                      print('Selected: ${_suggestionsId[index]}');
                      print('Selected: ${_suggestions[index]}');
                      _sessionToken = null;
                      _suggestions =
                          []; // trovare il modo di eliminare le suggestion dallo schermo dopo la selezione
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
