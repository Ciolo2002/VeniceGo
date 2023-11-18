import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

//tentativo di implementare una barra di ricerca che usi Places API
//TODO limitare le chiamate, aggiungendo ad esempio delay o call ogni tot caratteri
//sessionToken sembra funzionare, da vedere se questo limita i costi, in quanto le singole chiamate vengono comunque segnalataìe
//TODO introdurre limitazioni per tipo di luogo (ristoranti, monumenti, musei etc.), potenzialmente modificabili dall'utente

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  _LocationSearchScreenState createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];

  String? _sessionToken;

  String generateSessionToken() {
    var uuid = Uuid();
    return uuid.v4();
  }

  void fetchSuggestions(String input) async {
    if (_sessionToken == null) {
      _sessionToken = generateSessionToken();
    }

    const String apiKey = 'AIzaSyDFdHfwEJu1nt3F2aWkni1Hu8Zert0cbFA';
    const String baseUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';

    // Coordinates for Venice, Italy
    const double veniceLat = 45.4375;
    const double veniceLng = 12.3355;
    const int radius = 10000; //decide reaasonable restriction

    final String url =
        '$baseUrl?input=$input&components=country:IT&locationrestriction=circle:$radius@$veniceLat,$veniceLng&key=$apiKey&sessiontoken=$_sessionToken'; // Adjust parameters

    final response = await http.get(Uri.parse(url));

    print(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _suggestions = List<String>.from(
            data['predictions'].map((prediction) => prediction['description']));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (input) {
                fetchSuggestions(input);
              },
              decoration: InputDecoration(
                labelText: 'Search for a location',
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_suggestions[index]),
                    onTap: () {
                      // Handle selection
                      print('Selected: ${_suggestions[index]}');
                      _sessionToken = null;
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
