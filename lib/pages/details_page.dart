import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:venice_go/json_utility.dart' show PlaceDetails, Review;
import 'package:venice_go/pages/travel_page.dart';

import '../auth.dart';

//TODO: capire quali dati richiedere e implementarele nella chiamata
//TODO: creare il Layout per accogliere i dati
//TODO: gestione in caso di dati assenti

class DetailsPage extends StatefulWidget {
  final String placeID;

  const DetailsPage({super.key, required this.placeID});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

Future<List> getBookMarkFromFirebase() async {
  // Ottieni l'ID dell'utente attualmente loggato
  String userId = FirebaseAuth.instance.currentUser!.uid;
  // Ottieni un riferimento al documento utente nel database Firebase in tempo reale
  DatabaseReference userRef =
  FirebaseDatabase.instance.ref().child('users').child(userId);
  DataSnapshot snapshot = await userRef.get();
  // Ottieni i dati attuali dell'utente dal database Firebase in tempo reale
  Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
  return userData['bookmarkedPlace'];
}
List getBookMarkFromFirebaseDone(){
  List bookmarkedPlace = [];
  getBookMarkFromFirebase().then((value) => bookmarkedPlace = value);
  return bookmarkedPlace;
}

class _DetailsPageState extends State<DetailsPage> {
  late String placeID;
  dynamic details;
  List<String> imageUrl = [];
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    placeID = widget.placeID;
    isBookmarked = getBookMarkFromFirebaseDone().contains(placeID);
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
          'id,displayName,photos,shortFormattedAddress,reviews,currentOpeningHours,rating',
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
    setState(() {
      imageUrl.add(url);
    });
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
    setState(() {
      details = PlaceDetails.fromJson(jsonDetails);
    });
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
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
            elevation: 4.0,
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${details.reviews[0].authorName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rating: ${details.reviews[0].rating.toString()}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '${details.reviews[0].text}',
                  style: const TextStyle(
                      fontSize: 16.0), // Adjust the font size as needed
                ),
              ),
            ),
          ),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              review.authorName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Rating: ${review.rating.toString()}',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            review.text,
            style: const TextStyle(
                fontSize: 16.0), // Adjust the font size as needed
          ),
        ),
      ),
    );
  }

  Widget _buildOpeningHoursSection() {
    if (details != null &&
        details.openingHours != null &&
        details.openingHours.weekdayDescriptions.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'Opening Hours',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: details.openingHours.weekdayDescriptions.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  details.openingHours.weekdayDescriptions[index],
                  style: const TextStyle(fontSize: 16.0),
                ),
              );
            },
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildRating() {
    if (details != null && details.rating != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star,
            color: Colors.yellow,
            size: 20,
          ),
          const SizedBox(width: 5),
          Text(
            details.rating.toString(),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  void showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Required'),
          content: Text('You need to log in to bookmark this place.'),
          actions: [
            TextButton(
              onPressed: () {
                // Chiudi il popup
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }



  void saveRemoveBookmarkToFirebase(bool add) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('users').child(userId);
      List bookmarkedPlace = await getBookMarkFromFirebase();

      List<String> bookmarkedPlaces = List<String>.from(bookmarkedPlace);
      if (!bookmarkedPlaces.contains(placeID) && add) {
        bookmarkedPlaces.add(placeID);
        await userRef.update({'bookmarkedPlace': bookmarkedPlaces});
        //print('Bookmark added to Firebase for user $userId');
      } else if (bookmarkedPlaces.contains(placeID) && !add) {
        bookmarkedPlaces.remove(placeID);
        await userRef.update({'bookmarkedPlace': bookmarkedPlaces});
        //print('Bookmark removed from Firebase for user $userId');
      } else {
        // print('Bookmark already exists for user $userId');
      }
      // Aggiorna il valore del segnalibro nel documento utente nel database Firebase in tempo reale
      await userRef.update({'bookmarkedPlace': bookmarkedPlaces});
    } catch (e) {
      print('Error saving bookmark to Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context)  {
    return  Scaffold(
      appBar: AppBar(
        title: const Text('Place Details'),
        actions: [
          IconButton(
            icon: isBookmarked
                ? Icon(Icons.bookmark)
                : Icon(Icons.bookmark_border),
            onPressed: () {
              // Aggiunto controllo per il login
              if (Auth().currentUser != null) {
                setState(() {
                  isBookmarked = !isBookmarked;
                });

                // Esegui altre azioni desiderate qui in base al tuo stato
                if (isBookmarked) {
                  print('Place bookmarked!');
                  saveRemoveBookmarkToFirebase(true);
                } else {
                  print('Bookmark removed.');
                  saveRemoveBookmarkToFirebase(false);
                }
              } else {
                // Mostra il popup per richiedere il login
                showLoginDialog(context);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: details != null
            ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TravelPage(
                                  destinationsID:
                                      // Yes, this is horrible.
                                      // Dart has no native way of "casting" a type T to a List<T>
                                      // if the element of type T is only one. If we pass more than one
                                      // element then it's just a matter of calling .from method
                                      List<String>.filled(1, placeID)),
                            ),
                          );
                        },
                        child: const Text('Travel'),
                      ),
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
