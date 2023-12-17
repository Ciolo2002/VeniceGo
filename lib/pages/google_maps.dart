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
  final LatLng _veniceGeoCoords = const LatLng(45.4371908, 12.3345898);
  final Set<Marker> _markers = {};
  String _userInput = '';

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
    // Hand picked coordinates for Venice, ideally there should be already online coords
    // as a rectanble and I should just use them, but I couldn't find any.
    // These coords also take into account the fact that Venice is not a rectangle, thus we also have
    // Murano and Burano in the rectangle. Also Lido...
    LatLng bottomLeftVenice =
        const LatLng(45.337379185569965, 12.282943569192572);
    LatLng topRightVenice = const LatLng(45.4736707944578, 12.436851132952091);
    String body = '''{
          "textQuery" : "$userInput",  
          "locationRestriction": {
            "rectangle": {
              "low": {
                "latitude": ${bottomLeftVenice.latitude},
                "longitude": ${bottomLeftVenice.longitude}
              },
              "high": {
                "latitude": ${topRightVenice.latitude},
                "longitude": ${topRightVenice.longitude}
              }
            }
          }
    }
    ''';

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
    // This is a hacky way of printing the dialog to the user,
    // ideally we shouldn't call showDialog() from async methods
    // and the Dart compiler shouldn't allow it instead of just suggesting it, but hey ...
    // it works ¯\_(ツ)_/¯
    if (jsonMarkers.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const AlertDialog(
            title: Text("Warning"),
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 20,
            ),
            backgroundColor: Colors.greenAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            content: Text("No results found, please modify your search text."),
          );
        },
      );

      setState(() {
        _markers.clear();
      });
      return;
    }

    List<dynamic> placesList = jsonMarkers['places'];
    // Using a List<dynamic> makes it impossible to not use a temporary List<Place> variable
    // because the map() method is not available for List<dynamic>

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
                        _userInput = input;
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
              // SCRIVENDO NELLA BARRA DI RICERCA "SUPERMERCATI"
              // TODO TRAFROMARE L'ICONA DEL - PER NASCONDERE IN "LENTE DI INGRANDIMENTO" QUANDO IL TESTO è NASCOSTO
              // il click sulla lente di ingrandimento equivale a premenere invio, deve funzionare anche con l'invio della tastiera

              //TODO SE NON HO RISULTATI FAR COMPARIRE UN QUALCOSA CHE DICA CHE NON CI SONO RISULTATI

              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  // uso improptio del filter button per testare il Navigator push di un place ID verso la details page
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsPage(
                              placeID: 'ChIJgUbEo8cfqokR5lP9_Wh_DaM'),
                        ),
                      );
                    },
                    child: const Text('F'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => getMarkers('Museum'),
                    child: const Icon(Icons.museum, semanticLabel: 'Museum'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => getMarkers('Night Club'),
                    child: const Icon(Icons.celebration,
                        semanticLabel: 'Night Club'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => getMarkers('Park'),
                    child: const Icon(Icons.park, semanticLabel: 'Park'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => getMarkers('Supermarket'),
                    child: const Icon(Icons.shopping_cart,
                        semanticLabel: 'Supermarket'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => getMarkers(_userInput),
                    child: const Icon(Icons.backspace,
                        semanticLabel:
                            'Remove suggestion'), //TODO POSIZIONARE A FIANCO DELLA ICONA DELLA LENTE DI INGRANDIMENTO (mettere una icona della X)
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
