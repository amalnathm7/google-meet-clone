import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    return MaterialApp(
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        title: 'Gmeet',
        theme: ThemeData(
          accentColor: Colors.grey,
          dividerColor: Colors.transparent,
          primaryColor: Colors.teal[800],
          shadowColor: Colors.transparent,
        ),
        home: FirebaseAuth.instance.currentUser == null ? Welcome() : Home());
  }
}
