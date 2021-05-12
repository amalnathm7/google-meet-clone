import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gmeet/UI/splash.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          return !snapshot.hasData || snapshot.hasError || snapshot.data == null
              ? Splash()
              : Scaffold(
                  body: Container(
                    color: Colors.green[900],
                  ),
                );
        });
  }
}
