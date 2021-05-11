import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gmeet/Services/googleauth.dart';
import 'package:provider/provider.dart';
import 'UI/wrapper.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserIn>.value(
      value: GoogleAuth().userIn,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Meet',
        home: Wrapper(),
      ),
    );
  }
}