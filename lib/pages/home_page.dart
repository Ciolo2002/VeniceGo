import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:venice_go/navigation_bar.dart';
import 'package:venice_go/navigation_bar.dart';
import 'package:venice_go/pages/login_register_page.dart';
import 'package:venice_go/pages/verify_email_page.dart';

import '../auth.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _title(){
    return const Text('Firebase Auth');
  }

  Widget _userUid(){
    return Text(user?.email ?? 'User email');
  }

  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const LoginPage(),
  ];

  Widget _signOutButton() {
    return    ElevatedButton(
      // chiamo il metodo signOut() quando l'utente preme il bottone
      onPressed: signOut,
      style: TextButton.styleFrom(
        backgroundColor: Colors.indigo,
      ),
      child: const Text('Sign Out'),
    );
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: _title(),
            ),
            body: Container(
              height: double.infinity,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: /*Auth().currentUser!=null && Auth().currentUser!.emailVerified ? */<Widget>[
                    _userUid(),
                    _signOutButton(),
                  ]//: []// TODO TOGLIERE DALLA HOME PAGE E METTERLO NELLA PAGINA UTENTE
              ),
            ),
            bottomNavigationBar:
            /*Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.blue, // Customize the background color
            indicatorColor: Colors.indigo, // Customize the color of the selected tab indicator
            // Add more customizations here
            labelTextStyle: MaterialStateProperty.all(const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            iconTheme: MaterialStateProperty.all(const IconThemeData(color: Colors.white)),
          ),
      ), child: */const MyNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (int index) {
                _selectedIndex = index;
                //Navigator.of(context).push(MaterialPageRoute(builder: (context) => _pages[index]));
              },
            )//
            )
          //),

        )
    );

  }

}
