import 'package:flutter/material.dart';
import 'package:gmeet/Services/google_auth.dart';

class Login extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    GoogleAuth().signInWithGoogle(context);

    return Scaffold(
      body: Center(child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.green[800]),
      )),
    );
  }
}