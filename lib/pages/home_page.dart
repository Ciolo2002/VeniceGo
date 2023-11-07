import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:venice_go/navigation_bar.dart';
import 'package:venice_go/navigation_bar.dart';
import 'package:venice_go/pages/login_register_page.dart';
import 'package:venice_go/pages/verify_email_page.dart';

import '../auth.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> {


  late final String _userName;
  late final String _userSurname;
  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

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

  Widget _circleAvatar(){
    return const CircleAvatar(
      radius: 80,
      backgroundColor: Colors.black,
        child: CircleAvatar(
            radius: 75,
            backgroundImage: AssetImage(
                'assets/images/cafoscari.jpg'
            ),
            backgroundColor: Colors.white
        )
    );
  }

  Future<void> fetchUserData() async {
    final userId = Auth().currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref('users/$userId');

    DatabaseEvent event = await ref.once();

    if (event.snapshot.value != null) {
      final data = event.snapshot.value as Map;
      setState(() {
        _userName = data['Name'];
        _userSurname = data['Surname'];
      });
    }
  }

  Widget _userInfo(){
    fetchUserData();
    String userEmail = user?.email ?? 'User email';
    return Column(
      children: [
        Text("Name: $_userName"),
        Text("Surname: $_userSurname"),
        Text("Email: $userEmail")
      ],
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
            children: Auth().currentUser!=null && Auth().currentUser!.emailVerified ? <Widget>[
              _circleAvatar(),
              _userInfo(),
              _signOutButton(),
            ]:[]
        ),

      ),

    );
  }
}


