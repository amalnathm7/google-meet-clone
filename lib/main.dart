import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gmeet/Services/googleauth.dart';
import 'package:gmeet/UI/home.dart';
import 'package:gmeet/UI/welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gmeet',
        theme: ThemeData(
          accentColor: Colors.green[700],
        ),
        home: GoogleAuth().userIn == null ? Welcome() : Home());
  }
}
