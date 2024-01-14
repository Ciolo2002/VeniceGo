import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // variabili per la gestione del form
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controllerEmail = TextEditingController();
  String? errorMessage = '';

  // effettua il reset della password tramite Firebase Authentication
  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _controllerEmail.text,
        );
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        setState(() {
          errorMessage = _formatExceptionMessage(e.code);
        });
      }
    }
  }

  // formatta il messaggio di errore
  String _formatExceptionMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Email not valid';
      case 'user-not-found':
        return 'User not found';
      default:
        return 'Errore';
    }
  }

  // verifica che l'email sia valida
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Insert your email address';
    }
    final bool isValid = EmailValidator.validate(value);
    if (!isValid) {
      return 'Insert a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset password'),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.blue[200],
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _controllerEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton.icon(
                  onPressed: _resetPassword,
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Reset Password'),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
