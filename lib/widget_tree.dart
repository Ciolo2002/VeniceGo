import 'package:flutter/material.dart';
import 'pages/login_register_page.dart';
import 'package:venice_go/auth.dart';
import 'package:venice_go/pages/verify_email_page.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        //return HomePage();
        if (snapshot.hasData) {
          return VerifyEmailPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
