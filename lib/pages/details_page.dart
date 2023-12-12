import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:venice_go/json_utility.dart' show PlaceDetails;

//TODO: fare le chiamate per ottenere le foto
//TODO: capire quali dati richiedere e implementarele nella chiamata
//TODO: creare il Layout per accogliere i dati

class DetailsPage extends StatefulWidget {
  final String placeID;
  const DetailsPage({super.key, required this.placeID});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  // ID test, vedere come riceverlo dinamicamente dal marker successivamente
  late String placeID;
  dynamic details;

  @override
  void initState() {
    super.initState();
    placeID = widget.placeID;
    getDetails(placeID);
  }

  Future<dynamic> _getDetails(String id) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] as String;

    // API call section
    String url = 'https://places.googleapis.com/v1/places/$id';
    print(url);
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': 'id,displayName',
    };

    http.Response response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
    }
    return json.decode(response.body);
  }

  Future<void> getDetails(String id) async {
    dynamic jsonDetails = await _getDetails(id);
    print(jsonDetails);
    setState(() {
      details = PlaceDetails.fromJson(jsonDetails);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Place Details'),
      ),
      body: Center(
        child: details != null
            ? Column(
                children: [
                  Text(
                    details.id ?? 'Name not found',
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    details.displayName.text,
                    textAlign: TextAlign.center,
                  ),
                  Text(details.displayName.languageCode,
                      textAlign: TextAlign.center),
                ],
              )
            : const CircularProgressIndicator(), // Show loading circle while retrieving data
      ),
    );
  }
}
