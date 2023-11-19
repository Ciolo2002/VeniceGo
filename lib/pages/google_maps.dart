//TODO COMMANDI DA RUNNARE PER GOOGLE MAPS:
//flutter  pub add google_maps_flutter
//flutter  pub add http
// flutter  pub add json_serializable
//flutter  pub add --dev build_runner
//flutter  pub run build_runner build --delete-conflicting-outputs //POTREBBE NON SERVIRE, GENERA IL FILE locations.g.dart (che ho già fatto io)
//GOOGLE MAP ""S CONSOLE: https://console.cloud.google.com/google/maps-apis/home?project=venicego ACCEDETE CON LA MAIL DELL'UNIVERSITA'

//import 'dart:html';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../locations.dart' as locations;


class GoogleMaps extends StatefulWidget {
  const GoogleMaps({super.key});

  @override
  State<GoogleMaps> createState() => _MyGoogleMapsState();
}

class _MyGoogleMapsState extends State<GoogleMaps> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(45.4371908, 12.3345898); //COORDINATE DI VENEZIA




  final Map<String, Marker> _markers = {};
  /*+
  *QUESTO CI PERMETTE DI DEFINIRE DEI PUNTI DI INTERESSE CHE VOGLIAMO NOI SULLA MAPPA
  * per vedere il loro funzionamento (con gli esempi che da google, usare le coordiante
  * TODO CAPIRE COME FARE A CAMBIARE I PUNTI DI INTERESSE
   */
  Future<void> _onMapCreated(GoogleMapController controller) async {
    final googleOffices = await locations.getGoogleOffices();
    setState(() {
      _markers.clear();
      for (final office in googleOffices.offices) {
        final marker = Marker(
          markerId: MarkerId(office.name),
          position: LatLng(office.lat, office.lng),
          infoWindow: InfoWindow(
            title: office.name,
            snippet: office.address,
          ),
        );
        _markers[office.name] = marker;

      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Scaffold(
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            //target: LatLng(0,0), //COORDINATE DI TEST,
            target: _center, //COORDINATE DI VENEZIA
            zoom: 13.0,// ZOOM DI VENEZIA
            //zoom: 2.0,// ZOOM DI TEST
          ),
          markers: _markers.values.toSet(),
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          myLocationEnabled:true,
          myLocationButtonEnabled: true,
        ),
      ),
    );
  }
}
