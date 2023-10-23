import 'package:flutter/material.dart';
import 'pages/login_register_page.dart';
import 'package:venice_go/auth.dart';
import 'package:venice_go/pages/home_page.dart';
import 'package:venice_go/pages/verify_email_page.dart';

class WidgetTree extends StatefulWidget{
  const WidgetTree({Key? key}) : super(key: key);

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree>{
  @override
  Widget build(BuildContext context){
    return StreamBuilder(
      stream: Auth().authStateChanges,
      builder: (context, snapshot){
        if(snapshot.hasData){
          //return HomePage();
          return VerifyEmailPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }

}