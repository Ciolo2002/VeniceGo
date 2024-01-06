import 'dart:convert';

import 'package:flutter/material.dart';

import 'details_page.dart';

class BookMarked extends StatefulWidget {

  const BookMarked({super.key});
  @override
  State<BookMarked> createState() => _BookMarkedPageState();
}

class _BookMarkedPageState extends State<BookMarked> {
  final Map<String, dynamic> placesInfo = {};
  @override
  void initState() {
    super.initState();
    getBookMarkFromFirebase().then((value) {
      for(var v in value){
          placesInfo.putIfAbsent(v, () => getDetailsApi(v).then((googleValue) => googleValue));
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    const title = 'Bookmarked Places';
    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(title),
        ),
       body: ListView.builder(
          itemCount: placesInfo.length,
          itemBuilder: (context, index) {
            final key = placesInfo.keys.elementAt(index);
            return FutureBuilder(
              future: placesInfo[key],
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  Map<String, dynamic> dataMap = snapshot.data as Map<String, dynamic>;
                  print(dataMap);
                  return ListTile(
                    title: Text(dataMap['displayName']['text']),
                    subtitle: Text(dataMap['shortFormattedAddress']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsPage(
                            placeID: key
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return ListTile(
                    title: Text(key),
                    subtitle: Text('Error: ${snapshot.error}'),
                  );
                }
                return const ListTile(
                  title: Text('Loading...'),
                );
              },
            );
          },
        ),


      ),
    );
  }
}

