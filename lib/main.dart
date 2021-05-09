import 'package:flutter/material.dart';
import 'package:gmeet/UI/splash.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meet',
      home: Splash(),
    );
  }
}