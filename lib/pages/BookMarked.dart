import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:venice_go/navigation_bar.dart';

import '../auth.dart';
import 'details_page.dart';

class BookMarked extends StatefulWidget {
  const BookMarked({super.key});

  @override
  State<BookMarked> createState() => _BookMarkedPageState();
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

  void navigateToDetailsPage(String placeId) async {
    await Navigator.push(
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You need to login to see your bookmarks',
            style: TextStyle(fontSize: 24),
          ),
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
              child: Text("Login now")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Bookmarked Places';
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: title,
      home: Scaffold(
        body: Auth().currentUser == null
            ? _loginWidget()
            : Container(
                color: Colors.blue[200],
                child: ListView.builder(
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
                                title: Text(dataMap['displayName']['text']),
                                subtitle:
                                    Text(dataMap['shortFormattedAddress']),
                                onTap: () => navigateToDetailsPage(key),
                              );
                            } else if (snapshot.hasError) {
                              return ListTile(
                                title: Text(key),
                                subtitle: Text('Error: ${snapshot.error}'),
                              );
                            }
                            return ListTile(
                              title: CircularProgressIndicator(
                                color: Colors.blue,
                              ),
                            );
                          },
                        ));
                  },
                ),
              ),
      ),
    );
  }
}
