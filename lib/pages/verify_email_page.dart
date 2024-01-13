import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:venice_go/pages/home_page.dart';

/// Classe che gestisce la pagina di verifica dell'email
class VerifyEmailPage extends StatefulWidget {
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

/// Classe per le verifica dell'email
class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  // questo campo è necessario per evitare che l'utente possa inviare più email di verifica
  bool canResend = false;

  Timer? timer;

  /// Metodo che inizializza lo stato dell'oggetto e invia l'email di verifica
  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      sendEmailVerification();

      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  /// Metodo che distrugge il timer quando l'oggetto viene distrutto
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  /// Metodo che controlla se l'email è stata verificata
  /// e se è stata verificata distrugge il timer
  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerified) {
      timer?.cancel();
    }
  }

  /// Metodo che invia l'email di verifica
  /// e disabilita il bottone per 5 secondi
  /// quando il bottone viene riabilitato l'utente può inviare un'altra email
  Future sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    await user!.sendEmailVerification();

    setState(() => canResend = false);
    await Future.delayed(const Duration(seconds: 5));
    setState(() => canResend = true);
  }

  /// Metodo che costruisce la pagina con i widget necessari
  @override
  Widget build(BuildContext context) => isEmailVerified
      ? HomePage()
      : Scaffold(
          body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'An email has been sent to your account please verify',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: Icon(Icons.email, size: 32),
                  label: const Text(
                    'Resend Email',
                    style: TextStyle(fontSize: 24),
                  ),
                  onPressed: canResend ? sendEmailVerification : null),
              const SizedBox(height: 8),
              TextButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 24),
                ),
                onPressed: () => FirebaseAuth.instance.signOut(),
              )
            ],
          ),
        ));
}
