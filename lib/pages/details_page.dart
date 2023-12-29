import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:venice_go/json_utility.dart' show PlaceDetails, Review;
import 'package:url_launcher/url_launcher.dart';

//TODO: capire quali dati richiedere e implementarele nella chiamata
//TODO: creare il Layout per accogliere i dati
//TODO: gestione in caso di dati assenti

class DetailsPage extends StatefulWidget {
  final String placeID;
  const DetailsPage({super.key, required this.placeID});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late String placeID;
  dynamic details;
  List<String> imageUrl = [];

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
    // print(url);
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask':
          'id,displayName,photos,shortFormattedAddress,reviews,currentOpeningHours,rating,nationalPhoneNumber,websiteUri,editorialSummary',
    };

    http.Response response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
    }
    return json.decode(response.body);
  }

  Future<dynamic> getPhotos(String name) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] as String;
    // API call section
    const int maxHeightpx = 1000;
    const int maxWidthpx = 1000;
    String url =
        'https://places.googleapis.com/v1/$name/media?maxHeightPx=$maxHeightpx&maxWidthPx=$maxWidthpx&key=$apiKey';
    http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch photo. Error ${response.statusCode}: ${response.reasonPhrase}');
    }
    if (mounted) {
      setState(() {
        imageUrl.add(url);
      });
    }
  }

  Future<void> getDetails(String id) async {
    dynamic jsonDetails = await _getDetails(id);
    if (jsonDetails['photos'] != null) {
      imageUrl.clear();
      for (int i = 0; i < jsonDetails['photos'].length; i++) {
        getPhotos(jsonDetails['photos'][i]['name']);
      }
    } else {
      imageUrl.add(
          'https://upload.wikimedia.org/wikipedia/commons/d/d1/Image_not_available.png');
    }
    if (mounted) {
      setState(() {
        details = PlaceDetails.fromJson(jsonDetails);
      });
    }
  }

  // Method to show the enlarged image in a dialog
  void _showEnlargedImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop(); // Close the dialog on tap
            },
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain, // Adjust the image size in the dialog
            ),
          ),
        );
      },
    );
  }

  Widget _imageGallery() {
    return Card(
      elevation: 4.0,
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: imageUrl.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    _showEnlargedImage(imageUrl.elementAt(index));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      imageUrl.elementAt(index),
                      fit: BoxFit.cover,
                    ),
                  ),
                ));
          },
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            'Reviews',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (details != null && details.reviews.isNotEmpty)
          _buildReviewCard(details.reviews[0]),
        if (details != null && details.reviews.length > 1)
          ExpansionTile(
            title: const Text(
              'Show all reviews',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: details.reviews.length - 1,
                itemBuilder: (BuildContext context, int index) {
                  return _buildReviewCard(details.reviews[index + 1]);
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
      elevation: 2.0,
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              review.authorName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  review.rating.toString(),
                  style: const TextStyle(
                    fontStyle: FontStyle.normal,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.star,
                  color: Colors.yellow,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
        subtitle: review.text.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  review.text,
                  style: const TextStyle(fontSize: 16.0),
                ),
              )
            : SizedBox.shrink(),
      ),
    );
  }

  Widget _buildOpeningHoursSection() {
    if (details != null &&
        details.openingHours != null &&
        details.openingHours.weekdayDescriptions.isNotEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        elevation: 2.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text(
                'Opening Hours',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8.0),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: details.openingHours.weekdayDescriptions.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: Text(
                    details.openingHours.weekdayDescriptions[index],
                    style: TextStyle(fontSize: 16.0),
                  ),
                );
              },
            ),
            SizedBox(height: 5.0),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildRating() {
    if (details != null && details.rating != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            details.rating.toString(),
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(width: 5),
          Icon(
            Icons.star,
            color: Colors.yellow,
            size: 20,
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  Future<void> _launchCall(String num) async {
    final Uri _url = Uri.parse('tel:$num');
    if (!await launchUrl(_url)) {
      throw Exception('Could not call $num');
    }
  }

  Widget _buildPhoneNumber() {
    if (details != null &&
        details.nationalPhoneNumber != null &&
        details.nationalPhoneNumber != '') {
      return GestureDetector(
        onTap: () {
          _launchCall(details.nationalPhoneNumber);
        },
        child: Row(
          children: [
            Icon(Icons.phone),
            SizedBox(
              width: 5.0,
            ),
            Text(
              details.nationalPhoneNumber,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri _url = Uri.parse(url);
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  Widget _buildWebsiteUri() {
    if (details != null &&
        details.websiteUri != null &&
        details.websiteUri != '') {
      return GestureDetector(
        onTap: () {
          _launchUrl(details.websiteUri); // Function to launch URL
        },
        child: Row(
          children: [
            Icon(Icons.link),
            SizedBox(
              width: 5.0,
            ),
            Expanded(
              child: Text(
                details.websiteUri,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildEditorialSummary() {
    if (details != null &&
        details.editorialSummary != null &&
        details.editorialSummary.isNotEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            details.editorialSummary,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: details != null
            ? Text(details.displayName.text)
            : Text('Place Details'),
      ),
      body: Center(
        child: details != null
            ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                details.displayName.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                details.address,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      imageUrl.isNotEmpty
                          ? _imageGallery()
                          : const CircularProgressIndicator(),
                      const SizedBox(height: 24.0),
                      _buildRating(),
                      _buildEditorialSummary(),
                      _buildPhoneNumber(),
                      _buildWebsiteUri(),
                      _buildOpeningHoursSection(),
                      _buildReviewsSection(),
                    ],
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
