import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:venice_go/json_utility.dart' show PlaceDetails, Review;
import 'package:venice_go/pages/travel_page.dart';
import 'package:venice_go/pages/BookMarked.dart';
import '../auth.dart';
import 'package:url_launcher/url_launcher.dart';

//TODO: capire quali dati richiedere e implementarele nella chiamata
//TODO: creare il Layout per accogliere i dati
//TODO: gestione in caso di dati assenti

class DetailsPage extends StatefulWidget {
  final String placeID;
  final VoidCallback refreshCallback;

  const DetailsPage(
      {super.key, required this.placeID, required this.refreshCallback});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

Future<dynamic> getDetailsApi(String id, String whatINeed) async {
  final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] as String;
  // API call section
  String url = 'https://places.googleapis.com/v1/places/$id';
  // print(url);
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': apiKey,
    'X-Goog-FieldMask': whatINeed,
  };

  http.Response response = await http.get(Uri.parse(url), headers: headers);
  if (response.statusCode != 200) {
    throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
  }
  return json.decode(response.body);
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
  if (userData.keys.contains('bookmarkedPlace')) {
    return userData['bookmarkedPlace'];
  } else {
    return [];
  }
}

void saveRemoveBookmarkToFirebase(bool add, String placeID) async {
  try {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    DatabaseReference userRef =
        FirebaseDatabase.instance.ref().child('users').child(userId);
    List bookmarkedPlace = await getBookMarkFromFirebase();

    List<String> bookmarkedPlaces = List<String>.from(bookmarkedPlace);
    print(bookmarkedPlaces);
    if (!bookmarkedPlaces.contains(placeID) && add) {
      bookmarkedPlaces.add(placeID);
      await userRef.update({'bookmarkedPlace': bookmarkedPlaces});
      //print('Bookmark added to Firebase for user $userId');
    } else if (bookmarkedPlaces.contains(placeID) && !add) {
      bookmarkedPlaces.remove(placeID);
      await userRef.update({'bookmarkedPlace': bookmarkedPlaces});
      //print('Bookmark removed from Firebase for user $userId');
    }
    // Aggiorna il valore del segnalibro nel documento utente nel database Firebase in tempo reale
    await userRef.update({'bookmarkedPlace': bookmarkedPlaces});
  } catch (e) {
    print('Error saving bookmark to Firebase: $e');
  }
}

class _DetailsPageState extends State<DetailsPage> {
  late String placeID;
  dynamic details;
  List<String> imageUrl = [];
  bool isBookmarked = false;

  @override
  void dispose() {
    widget.refreshCallback(); // Chiamare la funzione di callback nel dispose
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    placeID = widget.placeID;
    getBookMarkFromFirebase().then((value) {
      isBookmarked = value.contains(placeID);
    });
    getDetails(placeID);
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
    dynamic jsonDetails = await getDetailsApi(id,
        'id,displayName,photos,shortFormattedAddress,reviews,currentOpeningHours,rating,nationalPhoneNumber,websiteUri,editorialSummary');
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
      color: Colors.blue[200],
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
    return details != null && details.reviews.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(child: SizedBox(width: 24)),
                      Container(
                        alignment: Alignment.centerRight,
                        child: _buildRating(),
                      ),
                    ],
                  )),
              _buildReviewCard(details.reviews[0]),
              if (details.reviews.length > 1)
                ExpansionTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Show more reviews',
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
          )
        : SizedBox
            .shrink(); // Returns an empty container if there are no reviews
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
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
      return Column(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            elevation: 2.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
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
                SizedBox(height: 4.0),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildRating() {
    if (details != null && details.rating != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            details.rating != 0.0 ? details.rating.toString() : 'Rating N/A',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 4),
          Icon(
            Icons.star,
            color: Colors.yellow,
            size: 24,
          ),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  void showLoginDialog(BuildContext context) {
    showPlatformDialog(
      context: context,
      builder: (BuildContext context) {
        return BasicDialogAlert(
          title: Text('Login Required'),
          content: Text('You need to login to bookmark this place.'),
          actions: [
            BasicDialogAction(
              onPressed: () {
                // Chiudi il popup
                Navigator.of(context).pop();
              },
              title: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchCall(String num) async {
    final Uri url = Uri.parse('tel:$num');
    if (!await launchUrl(url)) {
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
            Icon(Icons.phone, color: Colors.indigoAccent),
            SizedBox(
              width: 4.0,
            ),
            Text(
              details.nationalPhoneNumber,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Future<void> _launchUrl(String urlstr) async {
    final Uri url = Uri.parse(urlstr);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
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
            Icon(Icons.link, color: Colors.indigoAccent),
            SizedBox(
              width: 4.0,
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
      return SizedBox.shrink();
    }
  }

  Widget _buildEditorialSummary() {
    if (details != null &&
        details.editorialSummary != null &&
        details.editorialSummary.isNotEmpty) {
      return Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                details.editorialSummary,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildTitle() {
    return Card(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[200],
        title: const Text('Place Details'),
        actions: [
          IconButton(
            icon: isBookmarked
                ? Icon(Icons.bookmark, color: Colors.indigoAccent)
                : Icon(Icons.bookmark_border, color: Colors.indigoAccent),
            onPressed: () {
              // Aggiunto controllo per il login
              if (Auth().currentUser != null) {
                setState(() {
                  isBookmarked = !isBookmarked;
                });

                // Esegui altre azioni desiderate qui in base al tuo stato
                if (isBookmarked) {
                  print('Place bookmarked!');
                  saveRemoveBookmarkToFirebase(true, placeID);
                } else {
                  print('Bookmark removed.');
                  saveRemoveBookmarkToFirebase(false, placeID);
                  Navigator.pop(context, true);
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
                          : BookMarked.progressIndicator(32),
                      const SizedBox(height: 24.0),
                      _buildEditorialSummary(),
                      Padding(
                        // tel + rating
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(children: [
                          Expanded(child: _buildPhoneNumber()),
                          //_buildRating(),
                        ]),
                      ),
                      Padding(
                        // website
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: _buildWebsiteUri(),
                      ),
                      const SizedBox(height: 24.0),
                      _buildOpeningHoursSection(),
                      _buildReviewsSection(),
                    ],
                  ),
                ),
              )
            : BookMarked.progressIndicator(32),
      ),
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(
            side: BorderSide(width: 1, color: Colors.indigoAccent)),
        foregroundColor: Colors.white,
        backgroundColor: Colors.indigoAccent,
        child: const Icon(Icons.directions),
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
      ),
    );
  }
}
