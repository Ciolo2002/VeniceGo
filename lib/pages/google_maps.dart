//TODO COMMANDI DA RUNNARE PER GOOGLE MAPS:
//flutter  pub add google_maps_flutter
//flutter  pub add http
// flutter  pub add json_serializable
//flutter  pub add --dev build_runner
//flutter  pub run build_runner build --delete-conflicting-outputs //POTREBBE NON SERVIRE, GENERA IL FILE locations.g.dart (che ho già fatto io)
//GOOGLE MAP ""S CONSOLE: https://console.cloud.google.com/google/maps-apis/home?project=venicego ACCEDETE CON LA MAIL DELL'UNIVERSITA'

//import 'dart:html';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../json_utility.dart' show Place;
import 'details_page.dart';

class GoogleMaps extends StatefulWidget {
  const GoogleMaps({super.key});

  @override
  State<GoogleMaps> createState() => _MyGoogleMapsState();
}

class _MyGoogleMapsState extends State<GoogleMaps> {
  late GoogleMapController mapController;
  List<Place> _suggestions = [];
  bool _showListView = false;
  final LatLng _veniceGeoCoords = const LatLng(45.4371908, 12.3345898);
  final Set<Marker> _markers = {};
  String _userInput = '';
  final TextEditingController _controllerUserInput = TextEditingController();

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
    String body = '''
    {
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
    // Also it's becuase post request to Google Maps Places API returns Future<dynamic>
    // and rewriting the method to be synchronous would be too much work for now.
    // TODO: rewrite this method to be synchronous
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
    // Using a List<dynamic> makes it impossible to not use a temporary List<Place> variable
    // because the map() method is not available for List<dynamic>

    List<dynamic> placesList = jsonMarkers['places'];

    setState(() {
      _suggestions =
          List<Place>.from(placesList.map((place) => Place.fromJson(place)));
      _markers.clear();
      _markers
          .addAll(Set<Marker>.from(_suggestions.map((place) => Place.toMarker(
                place,
              ))));
    });
  }

  void _buttonSearchPressed(String userInput) {
    _controllerUserInput.text = userInput;
    setState(() {
      getMarkers(userInput);
      _showListView = false;
      _userInput= userInput;
    });
  }

  Widget _makeQuickSearchButton(String search, IconData icon) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          onPressed: () => _buttonSearchPressed(search),
          child: Icon(icon, semanticLabel: search),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: Scaffold(
        body: Column(
          children: [
            Container(
              color: Colors.blue[50],
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: TextField(
                        controller: _controllerUserInput,
                        onSubmitted: (input) {
                          getMarkers(input);
                          setState(() {
                            _showListView = true;
                            _userInput = input;
                          });
                        },
                        decoration: const InputDecoration(
                            labelText: 'Search for a location',
                            border: InputBorder.none),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (!_showListView) {
                          getMarkers(_userInput);
                        }
                        _showListView = !_showListView;
                      });
                    },
                    icon: Icon(_showListView ? Icons.remove : Icons.search),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.blue[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _makeQuickSearchButton("Museum", Icons.museum),
                  _makeQuickSearchButton("Night Club", Icons.celebration),
                  _makeQuickSearchButton("Park", Icons.park),
                  _makeQuickSearchButton("Supermarket", Icons.shopping_cart),
                ],
              ),
            ),
            if (_showListView)
              Expanded(
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      tileColor: Colors.blue[50],
                      focusColor: Colors.blue[200],
                      title: Text(_suggestions[index].displayName.text),
                      onTap: () {
                        _showListView = false;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsPage(
                              placeID: _suggestions[index].id,
                              refreshCallback: () => {},
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
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
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controllerUserInput.dispose();
    super.dispose();
  }
}
