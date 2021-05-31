import 'dart:async';
import 'package:agora_rtc_engine/rtc_channel.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gmeet/UI/home.dart';
import 'package:url_launcher/url_launcher.dart';

class Live extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LiveState();
  }
}

class LiveState extends State<Live> with TickerProviderStateMixin {
  var _user = FirebaseAuth.instance.currentUser;
  var volIcon = Icons.volume_up_outlined;
  var opacity = 0.0;
  var bottom = -60.0;
  var clr1 = Colors.green[800];
  var clr2 = Colors.transparent;
  var clr3 = Colors.transparent;
  var capPressed = false;
  var userNameClr = Colors.white;
  var currentIndex = 0;
  Timer timer = Timer(Duration(seconds: 0), null);
  TabController _tabController;
  RtcEngine engine;
  final appId = "6d4aa2fdccfd43438c4c811d12f16141";
  final token =
      "0066d4aa2fdccfd43438c4c811d12f16141IACA7K0J6vnDHNCwfcfn0K2zXfrA38eiKZ/ly20eP2qWxgXxcxEAAAAAEADEZWnp1Vi2YAEAAQDVWLZg";

  void mic() {
    setState(() {
      HomeState.isMuted = !HomeState.isMuted;
      Fluttertoast.cancel();
    });
    Fluttertoast.showToast(
      msg: HomeState.isMuted ? "Microphone off" : "Microphone on",
      gravity: ToastGravity.TOP,
      textColor: Colors.white,
      backgroundColor: Colors.transparent,
    );
  }

  void video() {
    setState(() {
      HomeState.isVidOff = !HomeState.isVidOff;
    });
  }

  void end() {
    Navigator.pop(context);
  }

  void singleTap() {
    timer.cancel();
    setState(() {
      if (opacity == 0) {
        opacity = 1;
        bottom = 20;
        userNameClr = Colors.transparent;
        timer = Timer(Duration(seconds: 5), btnFade);
      } else {
        opacity = 0;
        bottom = -60;
        userNameClr = Colors.white;
      }
    });
  }

  void btnFade() {
    if (opacity != 0)
      setState(() {
        opacity = 0;
        bottom = -60;
        userNameClr = Colors.white;
      });
  }

  void doubleTap() {}

  void speaker() {
    setState(() {
      clr1 = Colors.green[800];
      clr2 = Colors.transparent;
      clr3 = Colors.transparent;
      volIcon = Icons.volume_up_outlined;
    });
    Navigator.pop(context);
  }

  void phone() {
    setState(() {
      clr2 = Colors.green[800];
      clr1 = Colors.transparent;
      clr3 = Colors.transparent;
      volIcon = Icons.phone_in_talk;
    });
    Navigator.pop(context);
  }

  void audioOff() {
    setState(() {
      clr3 = Colors.green[800];
      clr2 = Colors.transparent;
      clr1 = Colors.transparent;
      volIcon = Icons.volume_off_outlined;
    });
    Navigator.pop(context);
  }

  void vol() {
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

  void cap() {
    setState(() {
      capPressed = !capPressed;
    });
    if (capPressed)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Captions are being turned on"),
          duration: Duration(milliseconds: 1000),
        ),
      );
  }

  void switchCamera() {
    Navigator.pop(context);
  }

  void present() {
    Navigator.pop(context);
  }

  void reportProblem() async {
    Navigator.pop(context);
    const _url = 'mailto:amalnathm7@gmail.com?subject=Feedback';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void reportAbuse() async {
    Navigator.pop(context);
    const _url = 'https://support.google.com/meet/contact/abuse';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void help() async {
    Navigator.pop(context);
    const _url = 'https://support.google.com';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void moreOptions() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: switchCamera,
                horizontalTitleGap: 3,
                leading: Icon(
                  Icons.flip_camera_android,
                  color: Colors.black54,
                ),
                title: Text(
                  "Switch Camera",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  cap();
                },
                horizontalTitleGap: 3,
                leading: Icon(
                  capPressed ? Icons.closed_caption : Icons.closed_caption_off,
                  color: Colors.black54,
                ),
                title: Text(
                  "Turn on captions",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
              ListTile(
                onTap: present,
                horizontalTitleGap: 3,
                leading: Icon(
                  Icons.present_to_all,
                  color: Colors.black54,
                ),
                title: Text(
                  "Present screen",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
              ListTile(
                onTap: reportProblem,
                horizontalTitleGap: 3,
                leading: Icon(
                  Icons.announcement_outlined,
                  color: Colors.black54,
                ),
                title: Text(
                  "Report a problem",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
              ListTile(
                onTap: reportAbuse,
                horizontalTitleGap: 3,
                leading: Icon(
                  Icons.report_gmailerrorred_outlined,
                  color: Colors.black54,
                ),
                title: Text(
                  "Report abuse",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
              ListTile(
                onTap: help,
                horizontalTitleGap: 3,
                leading: Icon(
                  Icons.help_outline,
                  color: Colors.black54,
                ),
                title: Text(
                  "Help",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                },
                horizontalTitleGap: 3,
                leading: Icon(
                  Icons.close_sharp,
                  color: Colors.black54,
                ),
                title: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );
        });
  }

  initAgora() async {
    RtcEngineConfig config = RtcEngineConfig(appId);
    engine = await RtcEngine.createWithConfig(config);

    engine.setEventHandler(
        RtcEngineEventHandler(joinChannelSuccess: (channel, uid, elapsed) {
      print("joinChannelSuccess");
    }, userJoined: (uid, elapsed) {
      print("userJoined $uid");
    }, userOffline: (int uid, UserOfflineReason reason) {
      print('userOffline $uid');
    }));
    await engine.enableVideo();
    await engine.joinChannel(token, "dev", null, 0);
  }

  @override
  void initState() {
    super.initState();
    singleTap();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.animation.addListener(() {
      setState(() {
        currentIndex = _tabController.animation.value.round();
      });
    });
    initAgora();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        body: Column(
          children: [
            GestureDetector(
              onTap: singleTap,
              onDoubleTap: doubleTap,
              child: Stack(
                children: [
                  Container(
                      color: Colors.black,
                      height: MediaQuery.of(context).size.height * .45,
                      width: MediaQuery.of(context).size.width,
                      child: HomeState.isVidOff
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 50,
                                ),
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: userNameClr,
                                  ),
                                )
                              ],
                            )
                          : SurfaceView()),
                  Positioned(
                    top: 40,
                    right: 0,
                    child: AnimatedOpacity(
                      curve: Curves.easeInOut,
                      opacity: opacity,
                      duration: Duration(milliseconds: 300),
                      child: Container(
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(volIcon),
                              onPressed: opacity == 0 ? null : vol,
                              color: Colors.white,
                              highlightColor: Colors.white10,
                              splashRadius: 25,
                            ),
                            IconButton(
                              icon: Icon(capPressed
                                  ? Icons.closed_caption
                                  : Icons.closed_caption_off),
                              onPressed: opacity == 0 ? null : cap,
                              color: Colors.white,
                            ),
                            IconButton(
                              icon: Icon(Icons.more_horiz),
                              onPressed: opacity == 0 ? null : moreOptions,
                              color: Colors.white,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    bottom: bottom,
                    left: (MediaQuery.of(context).size.width - 215) / 2,
                    curve: Curves.easeInOut,
                    duration: Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              height: 55,
                              width: 55,
                              duration: Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                  color: HomeState.isMuted
                                      ? Colors.red[800]
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: HomeState.isMuted
                                          ? Colors.transparent
                                          : Colors.white)),
                              child: IconButton(
                                splashRadius: 25,
                                splashColor: Colors.transparent,
                                icon: Icon(HomeState.isMuted
                                    ? Icons.mic_off_outlined
                                    : Icons.mic_none_outlined),
                                onPressed: mic,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              width: 25,
                            ),
                            Container(
                              height: 55,
                              width: 55,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      color: HomeState.isVidOff
                                          ? Colors.transparent
                                          : Colors.white)),
                              child: IconButton(
                                splashRadius: 25,
                                splashColor: Colors.transparent,
                                icon: Icon(Icons.call_end),
                                onPressed: end,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(
                              width: 25,
                            ),
                            AnimatedContainer(
                              height: 55,
                              width: 55,
                              duration: Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                  color: HomeState.isVidOff
                                      ? Colors.red[800]
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                      color: HomeState.isVidOff
                                          ? Colors.transparent
                                          : Colors.white)),
                              child: IconButton(
                                splashRadius: 25,
                                splashColor: Colors.transparent,
                                icon: Icon(HomeState.isVidOff
                                    ? Icons.videocam_off_outlined
                                    : Icons.videocam_outlined),
                                onPressed: video,
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
                            controller: _tabController,
                            indicatorColor: Colors.green[900],
                            indicatorSize: TabBarIndicatorSize.label,
                            tabs: [
                              Tab(
                                icon: Icon(
                                  currentIndex == 0
                                      ? Icons.people_alt
                                      : Icons.people_alt_outlined,
                                  color: currentIndex == 0
                                      ? Colors.green[900]
                                      : Colors.grey,
                                ),
                              ),
                              Tab(
                                icon: Icon(
                                  currentIndex == 1
                                      ? Icons.messenger_outlined
                                      : Icons.message_outlined,
                                  color: currentIndex == 1
                                      ? Colors.green[900]
                                      : Colors.grey,
                                ),
                              ),
                              Tab(
                                icon: Icon(
                                  currentIndex == 2
                                      ? Icons.info
                                      : Icons.info_outline,
                                  color: currentIndex == 2
                                      ? Colors.green[900]
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
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
