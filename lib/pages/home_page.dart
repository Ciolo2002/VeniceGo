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
    return Scaffold(
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

    );
  }

}
