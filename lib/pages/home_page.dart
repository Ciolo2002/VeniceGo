//import 'package:file_picker/file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'dart:io';

import '../auth.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _userName = '';
  late String _userSurname = '';
  late String _userPhoto = '';
  final User? user = Auth().currentUser;

  // campi per l'upload dei file
  PlatformFile? pickedFile;
  UploadTask? uploadTask;

  @override
  void initState() {
    fetchUserData();
    fetchProfileImage();

    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> fetchUserData() async {
    final userId = Auth().currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('users/$userId').get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        _userName = data['Name'];
        _userSurname = data['Surname'];
      });
    }
  }

  Future<void> fetchProfileImage() async {
    final userId = Auth().currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref('users/$userId');

    final event = await ref.get();

    if (event.value != null) {
      final data = event.value as Map;
      setState(() {
        if (data['ProfileImage'] != null) {
          _userPhoto = data['ProfileImage'];
        }
      });
    }
  }

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _signOutButton() {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            // chiamo il metodo signOut() quando l'utente preme il bottone
            onPressed: signOut,
            style: TextButton.styleFrom(
              backgroundColor: Colors.indigo,
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontSize: 16),
            ),
          )
        ]);
  }

  Widget _deleteAccountButton() {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            // chiamo il metodo signOut() quando l'utente preme il bottone
            onPressed: () async {
              _showDeleteAccountAlertDialog();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ]);
  }

  Future<void> _reauthenticateAndDelete() async {
    try {
      final providerData =
          FirebaseAuth.instance.currentUser?.providerData.first;

      // in caso implementassimo google e apple, per ora non sono previsti
      if (AppleAuthProvider().providerId == providerData!.providerId) {
        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithProvider(AppleAuthProvider());
      } else if (GoogleAuthProvider().providerId == providerData.providerId) {
        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithProvider(GoogleAuthProvider());
      } else {
        String? password = await _showPasswordInputDialog();

        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithCredential(EmailAuthProvider.credential(
          email: user!.email!,
          password: password!,
        ));
      }

      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      rethrow;
    }

    await Auth().signOut();
  }

  Future<String?> _showPasswordInputDialog() async {
    String? newPassword;

    await showPlatformDialog(
      context: context,
      builder: (_) => BasicDialogAlert(
        title: const Text("Confirm password"),
        content: Column(
          children: [
            const Text("To delete your account, please confirm your password."),
            Material(
                color: Colors.transparent,
                child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      obscureText: true,
                      onChanged: (value) {
                        newPassword = value;
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Your Password",
                      ),
                    ))),
          ],
        ),
        actions: <Widget>[
          BasicDialogAction(
            title: const Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
              newPassword = null;
            },
          ),
          BasicDialogAction(
            title: const Text("Delete Account",
                style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );

    return newPassword;
  }

  Future<void> _deleteAccountRealtimeDatabase() async {
    if (_userPhoto != '') {
      final ref2 = FirebaseStorage.instance.refFromURL(_userPhoto);
      await ref2.delete();
    }

    final userId = Auth().currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('users/$userId').get();

    if (snapshot.exists) {
      await ref.child('users/$userId').remove();
    }
  }

  Future<void> _showDeleteAccountAlertDialog() {
    return showPlatformDialog(
      context: context,
      builder: (_) => BasicDialogAlert(
        title: const Text("Attention!"),
        content: const Text(
            "Deleting your account will delete all your data. Are you sure you want to continue?"),
        actions: <Widget>[
          BasicDialogAction(
            title: const Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          BasicDialogAction(
            title: const Text("Delete Account",
                style: TextStyle(color: Colors.red)),
            onPressed: () async {
              _deleteAccountRealtimeDatabase();

              try {
                await FirebaseAuth.instance.currentUser!.delete();
              } on FirebaseAuthException catch (e) {
                print(e.code);

                if (e.code == "requires-recent-login") {
                  await _reauthenticateAndDelete();
                } else {
                  rethrow;
                }
              } catch (e) {
                rethrow;
              }

              await Auth().signOut();

              // chiudo il pop up solo se ha finito di cancellare l'account
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }



  Widget _circleAvatar() {
    if (pickedFile != null) {
      return CircleAvatar(
        radius: 80,
        backgroundColor: Colors.blue[900],
        child: ClipOval(
          child: SizedBox(
            width: 150, // Imposta la larghezza desiderata per l'immagine
            height: 150, // Imposta l'altezza desiderata per l'immagine
            child: Image.file(File(pickedFile!.path!), fit: BoxFit.cover),
          ),
        ),
      );
    } else {
      if (_userPhoto != '') {
        return CircleAvatar(
            radius: 80,
            backgroundColor: Colors.blue[800],
            child: CircleAvatar(
                radius: 75,
                backgroundImage: NetworkImage(_userPhoto),
                backgroundColor: Colors.white));
      } else {
        return const CircleAvatar(
            radius: 80,
            backgroundColor: Colors.blue,
            child: CircleAvatar(
                radius: 75,
                backgroundImage: AssetImage('assets/images/cafoscari.jpg'),
                backgroundColor: Colors.white));
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

  Future uploadFile() async {
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
      uploadTask = null;
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
            child: Stack(fit: StackFit.expand, children: [
              LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey,
                  color: Colors.green),
              Center(
                child: Text(
                  '${(progress * 100).roundToDouble()} %',
                  style: const TextStyle(color: Colors.white),
                ),
              )
            ]),
          );
        } else {
          return const SizedBox(height: 50);
        }
      });

  Widget _profileImage() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(children: <Widget>[
              _circleAvatar(),
              Positioned(bottom: 5, right: 5, child: _uploadSelectFileButton())
            ]),
            if (uploadTask != null && pickedFile != null) buildProgress()
          ],
        ));
  }

  Widget _uploadSelectFileButton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (pickedFile == null)
          Material(
              color: Colors.transparent,
              child: Ink(
                  decoration: const ShapeDecoration(
                    color: Colors.lightBlue,
                    shape: CircleBorder(),
                  ),
                  child: IconButton(
                    onPressed: selectFile,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    color: Colors.white,
                  ))),
        if (pickedFile != null)
          Material(
              color: Colors.transparent,
              child: Ink(
                  decoration: const ShapeDecoration(
                    color: Colors.green,
                    shape: CircleBorder(),
                  ),
                  child: IconButton(
                    onPressed: uploadFile,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    color: Colors.white,
                  )))
      ],
    );
  }

  Widget _userInfo() {
    String userEmail = user?.email ?? 'User email';
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(children: [
              Text("$_userName $_userSurname",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text(userEmail, style: const TextStyle(fontSize: 16))
            ])
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.blue[200],
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                Auth().currentUser != null && Auth().currentUser!.emailVerified
                    ? <Widget>[
                        _profileImage(),
                        _userInfo(),
                        SizedBox(height: 32),
                        _signOutButton(),
                        _deleteAccountButton(),
                      ]
                    : []),
      ),
    );
  }
}
