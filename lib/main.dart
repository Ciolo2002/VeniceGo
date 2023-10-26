import 'package:venice_go/navigation_bar.dart';

import 'widget_tree.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';



Future<void> main() async {
  // fondamentali per il funzionamento di Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options:
    DefaultFirebaseOptions.currentPlatform,
  ); // inizializza Firebase
  runApp(const MyApp());
}

class MyApp extends StatefulWidget{
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp>{

  int currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Venice Go')),
        body: SizedBox.expand(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            children: const [
              Text('Search'),
              Text('Saved'),
              Text('Account'),
              WidgetTree(),
            ],
          ),
        ),
        bottomNavigationBar: MyNavigationBar(
          onDestinationSelected: (index) {
            setState(() {
              _pageController.jumpToPage(index);
            });
          },
        ),
      )
    );
  }

}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
