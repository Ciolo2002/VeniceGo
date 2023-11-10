//import 'package:file_picker/file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import '../auth.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final String _userName;
  late final String _userSurname;
  late String _userPhoto = '';
  final User? user = Auth().currentUser;

  // campi per l'upload dei file
  PlatformFile? pickedFile;
  UploadTask? uploadTask;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _signOutButton() {
    return ElevatedButton(
      // chiamo il metodo signOut() quando l'utente preme il bottone
      onPressed: signOut,
      style: TextButton.styleFrom(
        backgroundColor: Colors.indigo,
      ),
      child: const Text('Sign Out'),
    );
  }

  Widget _circleAvatar() {
    if (pickedFile != null) {
      return CircleAvatar(
        radius: 80,
        backgroundColor: Colors.black,
        child: ClipOval(
          child: SizedBox(
            width: 150, // Imposta la larghezza desiderata per l'immagine
            height: 150, // Imposta l'altezza desiderata per l'immagine
            child: Image.file(File(pickedFile!.path!), fit: BoxFit.cover),
          ),
        ),
      );
    } else {
      if(_userPhoto != ''){
        return CircleAvatar(
            radius: 80,
            backgroundColor: Colors.black,
            child: CircleAvatar(
                radius: 75,
                backgroundImage: NetworkImage(_userPhoto),
                backgroundColor: Colors.white
            )
        );
      }else{
        return const CircleAvatar(
            radius: 80,
            backgroundColor: Colors.black,
            child: CircleAvatar(
                radius: 75,
                backgroundImage: AssetImage('assets/images/cafoscari.jpg'),
                backgroundColor: Colors.white
            )
        );
      }
    }
  }


  Future selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    setState(() {
      // pickedFile è un campo
      pickedFile = result.files.first;
    });
  }

  Future uploadFile() async{
    final path = 'files/${pickedFile!.name}';
    final file = File(pickedFile!.path!);

    final ref = FirebaseStorage.instance.ref().child(path);
    setState(() {
      uploadTask = ref.putFile(file);
    });

    final snapshot = await uploadTask!.whenComplete(() {});

    final urlDownload = await snapshot.ref.getDownloadURL();
    print('Download-Link: $urlDownload');

    DatabaseReference ref2 = FirebaseDatabase.instance.ref().child("users");

    String userId = Auth().currentUser!.uid;

    await ref2.child(userId).update({
      "ProfileImage": urlDownload,
    });

    setState(() {
      pickedFile = null;
    });
  }

  Widget buildProgress() => StreamBuilder<TaskSnapshot>(
    stream: uploadTask?.snapshotEvents,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final data = snapshot.data!;
        double progress = data.bytesTransferred / data.totalBytes;

        return SizedBox(
          height: 50,
          child: Stack(
            fit: StackFit.expand,
            children: [
              LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey,
                  color: Colors.green
              ),
              Center(
                child: Text(
                  '${(progress * 100).roundToDouble()} %',
                  style: const TextStyle(color: Colors.white),
                ),
              )
            ]
          ),
        );

      } else {
        return const SizedBox(height: 50);
      }
    }
  );

  Widget _profileImage() {
    return Column(
      children: [
        _circleAvatar(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: selectFile,
                child: const Icon(Icons.add_a_photo_outlined)),
            ElevatedButton(
                onPressed: uploadFile,
                child: const Icon(Icons.cloud_upload_outlined)),
          ],
        ),
        buildProgress()
      ],
    );
  }

  Future<void> fetchProfileImage() async {
    final userId = Auth().currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref('users/$userId');

    final event = await ref.get();

    if (event.value != null) {
      final data = event.value as Map;
      setState(() {
        if(data['ProfileImage'] != null) {
          _userPhoto = data['ProfileImage'];
        }
      });
    }
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

  Widget _userInfo() {
    fetchUserData();
    fetchProfileImage();
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
            children:
                Auth().currentUser != null && Auth().currentUser!.emailVerified
                    ? <Widget>[
                        _profileImage(),
                        _userInfo(),
                        _signOutButton(),
                      ]
                    : []),
      ),
    );
  }

}
