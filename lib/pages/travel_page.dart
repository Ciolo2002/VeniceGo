import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart" show dotenv;

class TravelPage extends StatefulWidget {
  const TravelPage({super.key, required this.placeID});
  final String placeID;
  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  late String _placeID;
  @override
  void initState() {
    super.initState();
    _placeID = widget.placeID;
  }

  Widget _createDirectionsWidget() {
    final String apiKEY = dotenv.env["GOOGLE_MAPS_API_KEY"] as String;
    // Temporary empty widget
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            height: double.infinity,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: Column(
              children: [Text("ID: $_placeID")],
            )));
  }
}
