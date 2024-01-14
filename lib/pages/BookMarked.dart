import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:venice_go/navigation_bar.dart';

import '../auth.dart';
import 'details_page.dart';

class BookMarked extends StatefulWidget {
  const BookMarked({super.key});

  @override
  State<BookMarked> createState() => _BookMarkedPageState();

  static Widget progressIndicator(double size) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: Colors.blue,
        ),
      ),
    );
  }
}

class _BookMarkedPageState extends State<BookMarked> {
  Map<String, dynamic> placesInfo = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData();
  }

  void loadData() {
    Map<String, dynamic> tmp = {}; //fondamentale per fare il refresh
    getBookMarkFromFirebase().then((value) {
      for (var v in value) {
        tmp.putIfAbsent(
          v,
          () => getDetailsApi(v, 'id,displayName,shortFormattedAddress')
              .then((googleValue) => googleValue),
        );
      }
      setState(() {
        placesInfo = tmp;
      }); // Force a rebuild after data is loaded
    });
  }

  void navigateToDetailsPage(String placeId, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsPage(
          placeID: placeId,
          refreshCallback: () {
            // Richiama loadData() quando torni indietro dalla pagina dei dettagli
            loadData();
          },
        ),
      ),
    );
  }

  Widget _loginWidget() {
    return Container(
      alignment: Alignment.center,
      color: Colors.blue[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You need to login to see your bookmarks',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () async {
                RenderBox renderbox =
                    myButtonKey.currentContext!.findRenderObject() as RenderBox;
                Offset position = renderbox.localToGlobal(Offset.zero);
                double x = position.dx;
                double y = position.dy;
                GestureBinding.instance.handlePointerEvent(
                    PointerDownEvent(position: Offset(x, y)));
                Future.delayed(Duration(milliseconds: 300));
                GestureBinding.instance.handlePointerEvent(PointerUpEvent(
                  position: Offset(x, y),
                ));
              },
              child: const Text(
                "Login now",
                style: TextStyle(fontSize: 16),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Bookmarked Places';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      home: Scaffold(
        body: Auth().currentUser == null
            ? _loginWidget()
            : Container(
                color: Colors.blue[200],
                child: placesInfo.isNotEmpty
                    ? ListView.builder(
                        itemCount: placesInfo.length,
                        itemBuilder: (context, index) {
                          final key = placesInfo.keys.elementAt(index);
                          return Dismissible(
                              key: Key(key),
                              onDismissed: (direction) {
                                saveRemoveBookmarkToFirebase(false, key);
                              },
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.only(right: 16.0),
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                              child: FutureBuilder(
                                future: placesInfo[key],
                                key: Key(key),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    Map<String, dynamic> dataMap =
                                        snapshot.data as Map<String, dynamic>;
                                    return ListTile(
                                      title:
                                          Text(dataMap['displayName']['text']),
                                      subtitle: Text(
                                          dataMap['shortFormattedAddress']),
                                      onTap: () =>
                                          navigateToDetailsPage(key, context),
                                    );
                                  } else if (snapshot.hasError) {
                                    return ListTile(
                                      title: Text(key),
                                      subtitle:
                                          Text('Error: ${snapshot.error}'),
                                    );
                                  }
                                  return ListTile(
                                    title: BookMarked.progressIndicator(32),
                                  );
                                },
                              ));
                        },
                      )
                    : Container(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: SizedBox(height: 8)),
                            Text(
                              "It looks like you haven't bookmarked anything yet...",
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Add your favorites here!",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Expanded(child: SizedBox(height: 8)),
                          ],
                        ),
                      ),
              ),
      ),
    );
  }
}
