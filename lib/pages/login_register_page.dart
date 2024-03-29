import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:venice_go/main.dart';
import 'package:venice_go/pages/forgot_password_page.dart';
import 'package:venice_go/pages/terms_and_conditions_page.dart';
import '../auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = true;
  bool isPasswordVisible = false;

  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerSurname = TextEditingController();

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerPasswordConfirm =
      TextEditingController();

  // effettua il login tramite Firebase Authentication
  Future<void> _signInWithEmailAndPassword() async {
    Map<String, TextEditingController> requiredF = {
      'email': _controllerEmail,
      'password': _controllerPassword
    };
    if (!_checkMapRequired(requiredF)) {
      return;
    }

    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _formatExceptionMessage(e.code);
      });
    }
  }

  // 1. registra l'utente tramite Firebase Authentication
  // 2. carica i dati dell'utente nel db realtime
  Future<void> _createUserWithEmailAndPassword() async {
    // mappa degli input obbligatori
    Map<String, TextEditingController> requiredF = {
      'name': _controllerName,
      'surname': _controllerSurname,
      'email': _controllerEmail,
      'password': _controllerPassword,
      'password_confirm': _controllerPasswordConfirm
    };

    if (!_checkMapRequired(requiredF)) {
      return;
    }
    // check per la conferma della password
    if (_controllerPassword.text != _controllerPasswordConfirm.text) {
       return setState(() {
        errorMessage = "Password does not match";
      });
    }
    if (!isChecked) {
      return setState(() {
        errorMessage = _formatExceptionMessage(
            "You must accept the Terms and Conditions");
      });
    }

    try {
      // creo l'utente con firebase Auth e lo carico in newUser
      final newUser = await Auth().createUSerWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );

      // newUser contiene l'id generato da Firebase
      String userId = newUser.user!.uid;

      DatabaseReference ref = FirebaseDatabase.instance.ref().child("users");

      // carico l'utente nel db realtime con l'Id di firebase Auth
      await ref.child(userId).set({
        "Name": _controllerName.text,
        "Surname": _controllerSurname.text,
        "Email": _controllerEmail.text,
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _formatExceptionMessage(e.code);
      });
    }
  }

  // controlla se i campi required del form sono vuoti, in caso interrompe
  bool _checkMapRequired(Map<String, TextEditingController> requiredF) {
    for (final fieldName in requiredF.keys) {
      if (!_hasValue(fieldName, requiredF[fieldName]!)) {
        return false; // Interrompi la funzione se uno dei campi richiesti è vuoto
      }
    }
    return true;
  }

  // controlla se i singoli campi sono vuoti
  bool _hasValue(String name, TextEditingController cont) {
    if (cont.text.isEmpty) {
      setState(() {
        errorMessage = _formatExceptionMessage("$name is required");
      });
      return false;
    }
    return true;
  }

  // formatta i messaggi di errore
  String _formatExceptionMessage(String val) {
    return val.replaceAll('_', ' ').replaceAll('-', ' ').capitalize();
  }

  // Widget per fare il toggle della password (l'occhio)
  Widget _entryField(String title, TextEditingController controller,
      {bool isPassword = false}) {
    return Container(
      color: Colors.blue[50],
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        onChanged: (String value) {
          setState(() {
            errorMessage = '';
          });
        },
        decoration: InputDecoration(
          labelText: title,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    // Based on isPasswordVisible state choose the icon
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  onPressed: () {
                    // Update the state i.e. toogle the state of isPasswordVisible variable
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  })
              : null,
        ),
      ),
    );
  }

  // Widget per il submit del form
  Widget _submitButton() {
    return ElevatedButton(
      onPressed: () {
        isLogin
            ? _signInWithEmailAndPassword()
            : _createUserWithEmailAndPassword();
      },
      child: Text(isLogin ? 'Login' : 'Register',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  // Widget per switchare tra Login e Registrazione
  Widget _loginOrRegisterButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          isLogin = !isLogin;
          errorMessage = '';
        });
      },
      child: Text(isLogin ? 'Register Instead' : 'Login Instead',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          )),
    );
  }

  // titolo della pagina
  //Widget _title() {
  //  return isLogin ? const Text('Login') : const Text('Registrazione');
  //}

  Widget _checkbox() {
    return Container(
      alignment: Alignment.center,
      child: Row(
        children: [
          MyCheckbox(),
          const Text("I agree to the "),
          GestureDetector(
            child: const Text(
              "Terms and Conditions",
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TermsAndConditionsPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // in base alla booleana isLogin carica il login o la registrazione
  @override
  Widget build(BuildContext context) {
    return isLogin ? _buildSignIn() : _buildRegister();
  }

  /*
  Le 2 seguenti funzioni ritornano un Widget Scaffold, ovvero un oggetto che
  struttura il layout della pagina caricando a sua volta altri widget
  */
  Widget _buildRegister() {
    return Scaffold(
        body: Container(
            color: Colors.blue[200],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _entryField('Name', _controllerName),
                    _entryField('Surname', _controllerSurname),
                    _entryField('Email', _controllerEmail),
                    _entryField('Password', _controllerPassword,
                        isPassword: true),
                    _entryField('Confirm Password', _controllerPasswordConfirm,
                        isPassword: true),
                    _checkbox(),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    _submitButton(),
                    _loginOrRegisterButton(),
                  ]),
            )));
  }

  Widget _buildSignIn() {
    return Scaffold(
      body: Container(
        color: Colors.blue[200],
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _entryField('Email', _controllerEmail),
              _entryField('Password', _controllerPassword, isPassword: true),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              _submitButton(),
              GestureDetector(
                child: Row(children: [
                  Expanded(
                      child: Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  )),
                  Align(
                      alignment: Alignment.centerRight,
                      child: _loginOrRegisterButton())
                ]),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ForgotPasswordPage(),
                  ),
                ),
              ),
            ]),
      ),
    );
  }
}

bool isChecked = false;

class MyCheckbox extends StatefulWidget {
  const MyCheckbox({super.key});

  @override
  State<MyCheckbox> createState() => _MyCheckboxState();
}

class _MyCheckboxState extends State<MyCheckbox> {
  @override
  Widget build(BuildContext context) {
    Color getColor(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.blue;
      }
      return Colors.blue;
    }

    return Checkbox(
      checkColor: Colors.white,
      fillColor: MaterialStateProperty.resolveWith(getColor),
      value: isChecked,
      onChanged: (bool? value) {
        setState(() {
          isChecked = value!;
        });
      },
    );
  }
}
