import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Database {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  void createMeeting() {
    const _chars = 'abcdefghijklmnopqrstuvwxyz';
    Random _rnd = Random.secure();
    String code = String.fromCharCodes(Iterable.generate(
        10, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
    code = code.substring(0, 3) +
        '-' +
        code.substring(3, 7) +
        '-' +
        code.substring(7, 10);

    _db.collection("meetings").doc(code).set({
      'host': _user.uid,
      'token':
          "0066d4aa2fdccfd43438c4c811d12f16141IABAanD8QludZe0NlduEoYUHG39o6s4m9wq+t5zskrcddM7T9ukAAAAAEAAg7xFxTeW4YAEAAQD1l7hg"
    }, SetOptions(merge: false));
  }

  void joinMeeting(String code) {

  }
}
