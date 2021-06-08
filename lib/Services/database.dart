import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gmeet/UI/home.dart';

class Database {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  DocumentSnapshot document;

  void createMeeting() {
    //const _chars = 'abcdefghijklmnopqrstuvwxyz';
    //Random _rnd = Random.secure();
    String code = "meet";
    /*String.fromCharCodes(Iterable.generate(
        10, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
    code = code.substring(0, 3) +
        '-' +
        code.substring(3, 7) +
        '-' +
        code.substring(7, 10);*/

    _db.collection("meetings").doc(code).set({
      'host': _user.uid,
      'token':
          "0066d4aa2fdccfd43438c4c811d12f16141IABAanD8QludZe0NlduEoYUHG39o6s4m9wq+t5zskrcddM7T9ukAAAAAEAAg7xFxTeW4YAEAAQD1l7hg"
    });

    _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(_user.uid)
        .set({
      'name': _user.displayName,
      'image_url': _user.photoURL,
      'isMuted': HomeState.isMuted,
      'isVidOff': HomeState.isVidOff
    });

    _db
        .collection("meetings")
        .doc(code)
        .collection("messages")
        .doc("messages")
        .set({});
  }

  Future<bool> ifMeetingExists(String code) async {
    document = await _db.collection("meetings").doc(code).get();
    if (document.exists) return true;
    return false;
  }

  void joinMeeting(String code) async {
    _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(_user.uid)
        .set({
      'name': _user.displayName,
      'image_url': _user.photoURL,
      'isMuted': HomeState.isMuted,
      'isVidOff': HomeState.isVidOff
    }, SetOptions(merge: false));
  }

  void sendMessage(String msg, String code) async {
    _db
        .collection("meetings")
        .doc(code)
        .collection("messages")
        .doc("messages")
        .update({
      DateTime.now().toString().substring(0, 19) +
          ":" +
          DateTime.now().millisecond.toString(): {_user.displayName: msg}
    });
  }

  void toggleMic(String code) async {
    _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(_user.uid)
        .update({
      'isMuted': HomeState.isMuted,
    });
  }

  void toggleCam(String code) async {
    _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(_user.uid)
        .update({
      'isVidOff': HomeState.isVidOff,
    });
  }
}
