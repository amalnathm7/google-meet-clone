import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gmeet/Services/googleauth.dart';
import 'package:gmeet/UI/splash.dart';
import 'package:provider/provider.dart';
import 'UI/wrapper.dart';
import 'models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        home: StreamBuilder<Object>(
            stream: FirebaseFirestore.instance.collection("users").snapshots(),
            builder: (context, snapshot) {
              return snapshot.hasData &&
                      !snapshot.hasError &&
                      snapshot.data != null
                  ? Wrapper()
                  : Splash();
            }),
      ),
    );
  }
}
