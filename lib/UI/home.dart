import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  var clr1 = Colors.green[800];
  var clr2 = Colors.transparent;
  var clr3 = Colors.transparent;
  var icon = Icons.volume_up_outlined;

  void mic() {}

  void video() {}

  void newMeeting() {}

  void meetingCode() {}

  void menu() {}

  void settings() {}

  void feedback() {}

  void abuse() {}

  void help() {}

  void _launchURL1() async {
    const _url = 'https://policies.google.com/terms';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void _launchURL2() async {
    const _url = 'https://policies.google.com/privacy';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void speaker() {
    setState(() {
      clr1 = Colors.green[800];
      clr2 = Colors.transparent;
      clr3 = Colors.transparent;
      icon = Icons.volume_up_outlined;
    });
    Navigator.pop(context);
  }

  void phone() {
    setState(() {
      clr2 = Colors.green[800];
      clr1 = Colors.transparent;
      clr3 = Colors.transparent;
      icon = Icons.phone_in_talk;
    });
    Navigator.pop(context);
  }

  void audioOff() {
    setState(() {
      clr3 = Colors.green[800];
      clr2 = Colors.transparent;
      clr1 = Colors.transparent;
      icon = Icons.volume_off_outlined;
    });
    Navigator.pop(context);
  }

  void btm() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: speaker,
                leading: Icon(
                  Icons.volume_up_outlined,
                  color: Colors.black54,
                ),
                title: Text(
                  "Speaker",
                  style: TextStyle(color: Colors.black),
                ),
                trailing: Icon(
                  Icons.check,
                  color: clr1,
                ),
              ),
              ListTile(
                onTap: phone,
                leading: Icon(
                  Icons.phone_in_talk,
                  color: Colors.black54,
                ),
                title: Text(
                  "Phone",
                  style: TextStyle(color: Colors.black),
                ),
                trailing: Icon(
                  Icons.check,
                  color: clr2,
                ),
              ),
              ListTile(
                onTap: audioOff,
                leading: Icon(
                  Icons.volume_off_outlined,
                  color: Colors.black54,
                ),
                title: Text(
                  "Audio off",
                  style: TextStyle(color: Colors.black),
                ),
                trailing: Icon(
                  Icons.check,
                  color: clr3,
                ),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                },
                leading: Icon(
                  Icons.close_sharp,
                  color: Colors.black54,
                ),
                title: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Center(
          child: Text(
            "Meet",
            style: TextStyle(
              fontFamily: 'Product Sans',
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: btm,
            splashRadius: 25,
            splashColor: Colors.transparent,
            icon: Icon(
              icon,
              color: Colors.white,
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: 120,
              child: DrawerHeader(
                padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  minLeadingWidth: 20,
                  leading: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        FirebaseAuth.instance.currentUser.photoURL,
                        height: 40,
                      )),
                  title: Text(FirebaseAuth.instance.currentUser.displayName),
                  subtitle: Text(FirebaseAuth.instance.currentUser.email),
                  trailing: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      "assets/logo.png",
                      height: 30,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              onTap: settings,
              dense: true,
              minLeadingWidth: 20,
              leading: Icon(
                Icons.settings_outlined,
                size: 22,
                color: Colors.black,
              ),
              title: Text(
                "Settings",
                style: TextStyle(fontSize: 15, fontFamily: 'Product Sans'),
              ),
            ),
            ListTile(
              onTap: feedback,
              dense: true,
              minLeadingWidth: 20,
              leading: Icon(
                Icons.feedback_outlined,
                size: 22,
                color: Colors.black,
              ),
              title: Text(
                "Send feedback",
                style: TextStyle(fontSize: 15, fontFamily: 'Product Sans'),
              ),
            ),
            ListTile(
              onTap: abuse,
              dense: true,
              minLeadingWidth: 20,
              leading: Icon(
                Icons.report_gmailerrorred_outlined,
                size: 22,
                color: Colors.black,
              ),
              title: Text(
                "Report abuse",
                style: TextStyle(fontSize: 15, fontFamily: 'Product Sans'),
              ),
            ),
            ListTile(
              onTap: help,
              dense: true,
              minLeadingWidth: 20,
              leading: Icon(
                Icons.help,
                size: 22,
                color: Colors.black,
              ),
              title: Text(
                "Help",
                style: TextStyle(fontSize: 15, fontFamily: 'Product Sans'),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(
                        thickness: 1,
                        height: 0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _launchURL2,
                            style: ButtonStyle(
                                overlayColor:
                                    MaterialStateProperty.all(Colors.black12),
                                padding: MaterialStateProperty.all(
                                    EdgeInsets.only(left: 5, right: 5))),
                            child: Text(
                              "Privacy Policy",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                          Text("  •  "),
                          TextButton(
                            onPressed: _launchURL1,
                            style: ButtonStyle(
                                overlayColor:
                                    MaterialStateProperty.all(Colors.black12),
                                padding: MaterialStateProperty.all(
                                    EdgeInsets.only(left: 5, right: 5))),
                            child: Text(
                              "Terms of Service",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white)),
                  child: IconButton(
                    splashRadius: 25,
                    splashColor: Colors.transparent,
                    icon: Icon(Icons.mic_none),
                    onPressed: mic,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 40,
                ),
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white)),
                  child: IconButton(
                    splashRadius: 25,
                    splashColor: Colors.transparent,
                    icon: Icon(Icons.videocam_outlined),
                    onPressed: video,
                    color: Colors.white,
                  ),
                )
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 5, bottom: 20, left: 10, right: 5),
                          child: ElevatedButton.icon(
                              icon: Icon(
                                Icons.add,
                                color: Colors.green[900],
                              ),
                              label: Text(
                                "New meeting",
                                style: TextStyle(
                                    color: Colors.green[900],
                                    fontFamily: 'Product Sans'),
                              ),
                              onPressed: newMeeting,
                              style: ElevatedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.grey[300], width: 1),
                                elevation: 0,
                                primary: Colors.white,
                                onPrimary: Colors.green[900],
                                shadowColor: Colors.transparent,
                              )),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 5, bottom: 20, left: 5, right: 10),
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.keyboard,
                              color: Colors.green[900],
                            ),
                            label: Text(
                              "Meeting code",
                              style: TextStyle(
                                  color: Colors.green[900],
                                  fontFamily: 'Product Sans'),
                            ),
                            onPressed: meetingCode,
                            style: ElevatedButton.styleFrom(
                              side:
                                  BorderSide(color: Colors.grey[300], width: 1),
                              elevation: 0,
                              primary: Colors.white,
                              onPrimary: Colors.green[900],
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Swipe up to see your meetings",
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontFamily: 'Product Sans',
                          fontSize: 12.5),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
