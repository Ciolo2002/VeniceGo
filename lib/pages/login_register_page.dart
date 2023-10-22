import 'dart:ffi';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth.dart';

class LoginPage extends StatefulWidget{
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{

  String? errorMessage = '';
  bool isLogin = true;

  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerSurname = TextEditingController();

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerPasswordConfirm = TextEditingController();

  Future<void> _signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> _createUserWithEmailAndPassword() async {
    if (_controllerPassword.text!=_controllerPasswordConfirm.text){
      return setState(() {
        errorMessage = "Passwords does not match";
      });
    }
    try {
      final newUser =
        await Auth().createUSerWithEmailAndPassword(
          email: _controllerEmail.text,
          password: _controllerPassword.text,
        );

      String userId = newUser.user!.uid;

      // TODO: fare eccezioni personalizzate se l'inserimento nel realtime db fallisce
      DatabaseReference ref = FirebaseDatabase.instance.ref().child("users");
      //DatabaseReference newUserRef = ref.push();

      // carico l'utente nel db realtime con l'Id di firebase Auth
      await ref.child(userId).set({
          "Name": _controllerName.text,
          "Surname": _controllerSurname.text,
      });

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Widget _title(){
    return isLogin ? const Text('Login'): const Text('Registrazione');
  }

  bool isPasswordVisible = false;

  Widget _entryField( String title, TextEditingController controller, {bool isPassword=false}){
    return TextField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      decoration: InputDecoration(
        labelText: title,
        suffixIcon: isPassword ? IconButton(
          icon: Icon(
            // Based on isPasswordVisible state choose the icon
            isPasswordVisible
                ? Icons.visibility
                : Icons.visibility_off,
            color: Theme.of(context).primaryColorDark,
          ),
          onPressed: () {
            // Update the state i.e. toogle the state of isPasswordVisible variable
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          }) : null,
      ),
    );
  }

  Widget _errorMessage(){
    return Text(errorMessage == '' ?'' : 'Humm ? $errorMessage');
  }

  Widget _submitButton(){
    return ElevatedButton(
      onPressed: () {
        isLogin ? _signInWithEmailAndPassword() : _createUserWithEmailAndPassword();
      },
      child: Text(isLogin ? 'Login' : 'Register'),
    );
  }

  Widget _loginOrRegisterButton(){
    return TextButton(
      onPressed: (){
        setState(() {
          isLogin = !isLogin;
          errorMessage = '';
        });
      },
      child: Text(isLogin ? 'Register Instead' : 'Login Instead'),
    );
  }

  @override
  Widget build(BuildContext context){
    return isLogin ? _buildSignIn() : _buildRegister();
  }

  Widget _buildRegister(){
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _entryField('Name', _controllerName),
              _entryField('Surname', _controllerSurname),
              _entryField('Email', _controllerEmail),
              _entryField('Password', _controllerPassword, isPassword: true),
              _entryField('Confirm Password', _controllerPasswordConfirm,isPassword: true),
              _errorMessage(),
              _submitButton(),
              _loginOrRegisterButton(),
            ]
        ),
      ),
    );
  }

  Widget _buildSignIn(){
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _entryField('Email', _controllerEmail),
              _entryField('Password', _controllerPassword, isPassword: true),
              _errorMessage(),
              _submitButton(),
              _loginOrRegisterButton(),
            ]
        ),
      ),
    );
  }

}
