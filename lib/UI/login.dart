import 'package:flutter/material.dart';
import 'package:gmeet/Services/googleauth.dart';

class Login extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    GoogleAuth().signInWithGoogle(context);

    return Scaffold();
  }
}