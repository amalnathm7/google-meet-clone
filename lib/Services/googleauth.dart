import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gmeet/UI/home.dart';
import 'package:gmeet/UI/login.dart';
import 'package:gmeet/models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleAuth {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth auth = FirebaseAuth.instance;

  UserIn _userIn(User user) {
    return user != null ? UserIn(uid: user.uid) : null;
  }

  Stream<UserIn> get userIn {
    return auth.authStateChanges().map(_userIn);
  }

  Future signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
            idToken: googleSignInAuthentication.idToken,
            accessToken: googleSignInAuthentication.accessToken);

        UserCredential userCredential = await auth.signInWithCredential(credential);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
        return _userIn(userCredential.user);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error signing in");
      signInWithGoogle(context);
    }
    Fluttertoast.showToast(msg: "Selecting an account is required");
    signInWithGoogle(context);
  }

  Future signOut(BuildContext context) async {
    try {
      await auth.signOut();
      await googleSignIn.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    } catch (e) {
    }
  }
}
