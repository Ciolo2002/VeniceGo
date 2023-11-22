import 'package:venice_go/navigation_bar.dart';
import 'package:venice_go/pages/google_maps.dart';
import 'package:venice_go/pages/location_search_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'navigation_data/navigation_data.dart';
import 'widget_tree.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // fondamentali per il funzionamento di Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // inizializza Firebase
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
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
  Widget build(BuildContext context) {
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
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  GoogleMaps(),
                  LocationSearchScreen(),
                  Text('Saved'),
                  WidgetTree(),
                ],
              ),
            ),
            bottomNavigationBar: Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: Colors.blue,
                  // Customize the background color
                  indicatorColor: Colors.indigo,
                  // Customize the color of the selected tab indicator
                  // Add more customizations here
                  labelTextStyle: MaterialStateProperty.all(const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
                  iconTheme: MaterialStateProperty.all(
                      const IconThemeData(color: Colors.white)),
                ),
              ),
              child: MyNavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    currentIndex = index;
                    _pageController.animateToPage(index,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease);
                  });
                },
              ),
            )));
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
