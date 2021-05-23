import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Database {
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  void initialiseUser() {
    _db.collection("users").add({'uid': _user.uid});
  }

  void createMeeting() {}
}
