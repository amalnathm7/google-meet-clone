import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gmeet/Services/googleauth.dart';
import 'package:gmeet/UI/live.dart';
import 'package:gmeet/UI/meetingcode.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
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
  static var isMicPressed = false;
  static var isVidPressed = false;
  var isAccPressed = false;
  var sheet = false;
  var snack = true;
  var logOut = false;
  User _user = FirebaseAuth.instance.currentUser;
  CameraController _controller;

  @override
  void initState() {
    super.initState();
    camera();
  }

  void camera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras.last, ResolutionPreset.max);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

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

  void newMeeting() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Live()),
    );
  }

  void meetingCode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeetingCode()),
    );
  }

  void menu() {}

  void settings() {}

  void feedback() async {
    const _url = 'mailto:amalnathm7@gmail.com?subject=Feedback';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void abuse() async {
    const _url = 'https://support.google.com/meet/contact/abuse';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void help() async {
    const _url = 'https://support.google.com';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void _launchURL1() async {
    const _url = 'https://policies.google.com/terms';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void _launchURL2() async {
    const _url = 'https://policies.google.com/privacy';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void manageAccount() async {
    const _url = 'https://myaccount.google.com';
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

  void logout() {
    setState(() {
      logOut = true;
    });
    GoogleAuth().signOut(context);
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

  void refresh() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: sheet
          ? AppBar(
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.black54),
              title: Text(
                "Your meetings",
                style: TextStyle(
                    color: Colors.black87, fontFamily: 'Product Sans'),
              ),
              actions: <Widget>[
                IconButton(
                  onPressed: refresh,
                  splashRadius: 20,
                  splashColor: Colors.transparent,
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.black54,
                  ),
                )
              ],
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              title: Text(
                "Meet",
                style: TextStyle(
                  fontFamily: 'Product Sans',
                ),
              ),
              centerTitle: true,
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
            SizedBox(
              height: 40,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              onExpansionChanged: (val) {
                setState(() {
                  isAccPressed = val;
                });
              },
              leading: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _user != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          _user.photoURL,
                          height: 36,
                        ))
                    : SizedBox(),
              ),
              title: Text(
                _user != null ? _user.displayName : "",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: 'Product Sans',
                    fontSize: 15,
                    color: Colors.black),
              ),
              subtitle: RichText(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                text: TextSpan(children: [
                  TextSpan(
                    text: _user != null ? _user.email + " " : "",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  WidgetSpan(
                      child: Icon(
                    isAccPressed
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black54,
                    size: 18,
                  ))
                ]),
              ),
              trailing: logOut
                  ? Padding(
                      padding: const EdgeInsets.only(right: 28),
                      child: Container(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                          )),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: IconButton(
                            iconSize: 20,
                            splashRadius: 20,
                            color: Colors.black54,
                            splashColor: Colors.transparent,
                            icon: Icon(
                              Icons.logout,
                            ),
                            onPressed: logout,
                          )),
                    ),
              children: [
                TextButton(
                    style: TextButton.styleFrom(
                        shadowColor: Colors.grey,
                        onSurface: Colors.grey,
                        minimumSize: Size(180, 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(width: 0.5),
                        )),
                    onPressed: manageAccount,
                    child: Text(
                      "Manage your Google Account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.black54,
                          fontFamily: 'Product Sans',
                          fontSize: 12),
                    )),
                SizedBox(
                  height: 5,
                )
              ],
            ),
            Divider(
              color: Colors.black12,
              thickness: 1,
              height: 0,
            ),
            ListTile(
              onTap: settings,
              dense: true,
              minLeadingWidth: 20,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: Colors.black,
                ),
              ),
              title: Text(
                "Settings",
                style: TextStyle(fontSize: 14, fontFamily: 'Product Sans'),
              ),
            ),
            ListTile(
              onTap: feedback,
              dense: true,
              minLeadingWidth: 20,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.feedback_outlined,
                  size: 20,
                  color: Colors.black,
                ),
              ),
              title: Text(
                "Send feedback",
                style: TextStyle(fontSize: 14, fontFamily: 'Product Sans'),
              ),
            ),
            ListTile(
              onTap: abuse,
              dense: true,
              minLeadingWidth: 20,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.report_gmailerrorred_outlined,
                  size: 20,
                  color: Colors.black,
                ),
              ),
              title: Text(
                "Report abuse",
                style: TextStyle(fontSize: 14, fontFamily: 'Product Sans'),
              ),
            ),
            ListTile(
              onTap: help,
              dense: true,
              minLeadingWidth: 20,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.help,
                  size: 20,
                  color: Colors.black,
                ),
              ),
              title: Text(
                "Help",
                style: TextStyle(fontSize: 14, fontFamily: 'Product Sans'),
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
      body: SlidingSheet(
        duration: Duration(milliseconds: 300),
        color: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 3,
        cornerRadiusOnFullscreen: 0,
        closeOnBackButtonPressed: true,
        snapSpec: SnapSpec(
            initialSnap: 200,
            snappings: [200, double.infinity],
            positioning: SnapPositioning.pixelOffset),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isVidPressed
                ? _user != null
                    ? Center(
                        child: ClipRRect(
                          child: Image.network(
                            _user.photoURL,
                            height: 80,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      )
                    : SizedBox()
                : _controller != null
                    ? _controller.value.isInitialized
                        ? CameraPreview(_controller)
                        : SizedBox()
                    : SizedBox(),
            SizedBox(
              height: MediaQuery.of(context).size.height * .15,
            ),
          ],
        ),
        addTopViewPaddingOnFullscreen: false,
        builder: (context, state) {
          return SheetListenerBuilder(buildWhen: (oldState, newState) {
            if (snack)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Signed in as " + _user?.email.toString()),
                  duration: Duration(milliseconds: 1000),
                ),
              );
            snack = false;
            setState(() {
              if (newState.isExpanded) {
                sheet = true;
              } else {
                sheet = false;
              }
            });
            return true;
          }, builder: (context, state) {
            return state.isExpanded
                ? Container(
                    height: MediaQuery.of(context).size.height,
                    color: Colors.white,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            height: 55,
                            width: 55,
                            duration: Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                                color: isMicPressed
                                    ? Colors.red[800]
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isMicPressed
                                        ? Colors.transparent
                                        : Colors.white)),
                            child: IconButton(
                              splashRadius: 25,
                              splashColor: Colors.transparent,
                              icon: Icon(isMicPressed
                                  ? Icons.mic_off_outlined
                                  : Icons.mic_none_outlined),
                              onPressed: mic,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                          ),
                          AnimatedContainer(
                            height: 55,
                            width: 55,
                            duration: Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                                color: isVidPressed
                                    ? Colors.red[800]
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: isVidPressed
                                        ? Colors.transparent
                                        : Colors.white)),
                            child: IconButton(
                              splashRadius: 25,
                              splashColor: Colors.transparent,
                              icon: Icon(isVidPressed
                                  ? Icons.videocam_off_outlined
                                  : Icons.videocam_outlined),
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
                            Container(
                              height: 10,
                              width: 25,
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          width: 2, color: Colors.black12))),
                            ),
                            SizedBox(
                              height: 10,
                            ),
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
                                              color: Colors.grey[300],
                                              width: 1),
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
                                        side: BorderSide(
                                            color: Colors.grey[300], width: 1),
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
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                "Swipe up to see your meetings",
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 12),
                              ),
                            ),
                            Container(
                              height: 500,
                            )
                          ],
                        ),
                      )
                    ],
                  );
          });
        },
      ),
    );
  }
}
