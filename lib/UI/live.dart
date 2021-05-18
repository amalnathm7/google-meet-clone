import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Live extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LiveState();
  }
}

class LiveState extends State<Live> {
  var _user = FirebaseAuth.instance.currentUser;
  var isMicPressed = false;
  var isVidPressed = false;

  void mic() {
    setState(() {
      isMicPressed = !isMicPressed;
      Fluttertoast.cancel();
    });
    Fluttertoast.showToast(
      msg: isMicPressed ? "Microphone off" : "Microphone on",
      gravity: ToastGravity.CENTER,
      textColor: Colors.white,
      backgroundColor: Colors.transparent,
    );
  }

  void video() {
    setState(() {
      isVidPressed = !isVidPressed;
    });
  }

  void tile() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        body: Column(
          children: [
            ListTile(
              tileColor: Colors.black,
              onTap: tile,
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 0,
              title: Container(
                color: Colors.black,
                height: MediaQuery.of(context).size.height * .45,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      child: Image.network(
                        _user.photoURL,
                        height: 80,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      _user.displayName,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.55,
              child: Material(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Colors.black12))),
                        child: Material(
                          color: Colors.white,
                          child: TabBar(
                            tabs: [
                              Tab(
                                  icon: Icon(
                                Icons.people_alt_outlined,
                                color: Colors.grey,
                              )),
                              Tab(
                                  icon: Icon(
                                Icons.message_outlined,
                                color: Colors.grey,
                              )),
                              Tab(
                                  icon: Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                              )),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ListView(),
                            ListView(),
                            ListView(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
