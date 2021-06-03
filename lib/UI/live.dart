import 'dart:async';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gmeet/UI/home.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class Live extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LiveState();
  }
}

class LiveState extends State<Live> with TickerProviderStateMixin {
  var _user = FirebaseAuth.instance.currentUser;
  var opacity = 0.0;
  var bottom = -60.0;
  var capPressed = false;
  var userNameClr = Colors.white;
  var currentIndex = 0;
  Timer timer = Timer(Duration(seconds: 0), null);
  TabController _tabController;
  TextEditingController _textEditingController = TextEditingController();

  RtcEngine _engine;
  final appId = "6d4aa2fdccfd43438c4c811d12f16141";
  final token =
      "0066d4aa2fdccfd43438c4c811d12f16141IABAanD8QludZe0NlduEoYUHG39o6s4m9wq+t5zskrcddM7T9ukAAAAAEAAg7xFxTeW4YAEAAQD1l7hg";
  List<String> _users = [
    FirebaseAuth.instance.currentUser.displayName + ' (You)'
  ];
  List<String> _messages = [];
  List<String> _messageUsers = [];
  List<String> _messageTime = [];

  void mic() {
    setState(() {
      HomeState.isMuted = !HomeState.isMuted;
      Fluttertoast.cancel();
    });
    _engine.muteLocalAudioStream(HomeState.isMuted);
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
    _engine.enableLocalVideo(!HomeState.isVidOff);
  }

  void end() {
    _engine.leaveChannel();
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
    _engine.muteAllRemoteAudioStreams(false);
    setState(() {
      HomeState.clr1 = Colors.green[800];
      HomeState.clr2 = Colors.transparent;
      HomeState.clr3 = Colors.transparent;
      HomeState.soundIcon = Icons.volume_up_outlined;
    });
    Navigator.pop(context);
  }

  void phone() {
    _engine.muteAllRemoteAudioStreams(false);
    setState(() {
      HomeState.clr2 = Colors.green[800];
      HomeState.clr1 = Colors.transparent;
      HomeState.clr3 = Colors.transparent;
      HomeState.soundIcon = HomeState.isHeadphoneConnected ? Icons.headset_outlined : Icons.volume_up_outlined;
    });
    Navigator.pop(context);
  }

  void audioOff() {
    _engine.muteAllRemoteAudioStreams(true);
    setState(() {
      HomeState.clr3 = Colors.green[800];
      HomeState.clr2 = Colors.transparent;
      HomeState.clr1 = Colors.transparent;
      HomeState.soundIcon = Icons.volume_off_outlined;
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
              SizedBox(
                height: 10,
              ),
              ListTile(
                onTap: speaker,
                dense: true,
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
                  color: HomeState.clr1,
                ),
              ),
              ListTile(
                onTap: phone,
                dense: true,
                leading: Icon(
                  HomeState.isHeadphoneConnected ? Icons.headset_outlined : Icons.phone_in_talk,
                  color: Colors.black54,
                ),
                title: Text(
                  HomeState.isHeadphoneConnected ? "Wired headphones" : "Phone",
                  style: TextStyle(color: Colors.black),
                ),
                trailing: Icon(
                  Icons.check,
                  color: HomeState.clr2,
                ),
              ),
              ListTile(
                onTap: audioOff,
                dense: true,
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
                  color: HomeState.clr3,
                ),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                },
                dense: true,
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

  void captions() {
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
    _engine.switchCamera();
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
                  captions();
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

  void sendMsg() {
    _messages.insert(0, _textEditingController.text);
    _messageUsers.insert(0, "You");
    _messageTime.insert(0, DateFormat('hh:mm a').format(DateTime.now()));
    _textEditingController.clear();
    setState(() {});
  }

  void share() {}

  initAgora() async {
    RtcEngineConfig config = RtcEngineConfig(appId);
    _engine = await RtcEngine.createWithConfig(config);

    _engine.setEventHandler(
        RtcEngineEventHandler(joinChannelSuccess: (channel, uid, elapsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You joined $channel"),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }, userJoined: (uid, elapsed) {
      _users.add(uid.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$uid joined this meeting"),
          duration: Duration(milliseconds: 1000),
        ),
      );
      setState(() {});
    }, userOffline: (int uid, UserOfflineReason reason) {
      _users.remove(uid.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$uid left this meeting"),
          duration: Duration(milliseconds: 1000),
        ),
      );
      setState(() {});
    }));

    await _engine.enableVideo();
    await _engine.enableAudio();

    await _engine.joinChannel(token, "meet", null, 0);

    _engine.muteLocalAudioStream(HomeState.isMuted);
    _engine.enableLocalVideo(!HomeState.isVidOff);
  }

  @override
  void initState() {
    super.initState();
    singleTap();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.animation.addListener(() {
      setState(() {
        currentIndex = _tabController.animation.value.round();
        if (currentIndex != 1) {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        }
      });
    });
    initAgora();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textEditingController.dispose();
    _engine.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = EdgeInsets.fromWindowPadding(
        WidgetsBinding.instance.window.viewInsets,
        WidgetsBinding.instance.window.devicePixelRatio);
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
                    height: viewInsets.bottom == 0
                        ? MediaQuery.of(context).size.height * .45
                        : (MediaQuery.of(context).size.height -
                                viewInsets.bottom) *
                            .45,
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
                        : _users.length == 1
                            ? RtcLocalView.SurfaceView()
                            : RtcRemoteView.SurfaceView(
                                uid: int.parse(_users[1]),
                              )),
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
                            icon: Icon(HomeState.soundIcon),
                            onPressed: opacity == 0 ? null : vol,
                            color: Colors.white,
                            highlightColor: Colors.white10,
                            splashRadius: 25,
                          ),
                          IconButton(
                            icon: Icon(capPressed
                                ? Icons.closed_caption
                                : Icons.closed_caption_off),
                            onPressed: opacity == 0 ? null : captions,
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
            height: viewInsets.bottom == 0
                ? MediaQuery.of(context).size.height * .55
                : (MediaQuery.of(context).size.height - viewInsets.bottom) *
                    .55,
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    currentIndex == 0
                                        ? Icons.people_alt
                                        : Icons.people_alt_outlined,
                                    color: currentIndex == 0
                                        ? Colors.green[900]
                                        : Colors.grey,
                                  ),
                                  Text(
                                    ' (' + _users.length.toString() + ')',
                                    style: TextStyle(
                                      color: currentIndex == 0
                                          ? Colors.green[900]
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              child: Icon(
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
                          ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: 70,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        color: Colors.grey[200],
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: ClipRRect(
                                                child: Image.network(
                                                  _user.photoURL,
                                                  height: 50,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                            ),
                                            Positioned(
                                              right: HomeState.isMuted ? 5 : 3,
                                              bottom: HomeState.isMuted ? 5 : 0,
                                              child: Container(
                                                  child: Padding(
                                                    padding: HomeState.isMuted
                                                        ? EdgeInsets.all(3.0)
                                                        : EdgeInsets.zero,
                                                    child: Icon(
                                                      HomeState.isMuted
                                                          ? Icons.mic_off
                                                          : Icons
                                                              .more_horiz_rounded,
                                                      color: HomeState.isMuted
                                                          ? Colors.white
                                                          : Colors.green[700],
                                                      size: HomeState.isMuted
                                                          ? 18
                                                          : 28,
                                                    ),
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: HomeState.isMuted
                                                        ? Colors.red[800]
                                                        : Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                  )),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 14),
                                        child: Text(_users[index]),
                                      )
                                    ],
                                  ),
                                );
                              }),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    FocusScopeNode currentFocus =
                                        FocusScope.of(context);
                                    if (!currentFocus.hasPrimaryFocus) {
                                      currentFocus.unfocus();
                                    }
                                  },
                                  child: ListView.builder(
                                      shrinkWrap: true,
                                      reverse: true,
                                      padding: EdgeInsets.only(left: 10),
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    _messageUsers[index],
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 8,
                                                  ),
                                                  Text(
                                                    _messageTime[index],
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[700],
                                                    ),
                                                  )
                                                ],
                                              ),
                                              SizedBox(
                                                height: 3,
                                              ),
                                              Text(_messages[index]),
                                              SizedBox(
                                                height: 10,
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        top: BorderSide(
                                            color: Colors.grey[300]))),
                                child: TextField(
                                  controller: _textEditingController,
                                  onChanged: (text) {
                                    setState(() {});
                                  },
                                  onSubmitted: (text) {
                                    setState(() {});
                                  },
                                  cursorColor: Colors.green[800],
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: TextStyle(fontSize: 12),
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(15),
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.send),
                                        iconSize: 20,
                                        color: Colors.green[800],
                                        splashRadius: 20,
                                        onPressed:
                                            _textEditingController.text.isEmpty
                                                ? null
                                                : sendMsg,
                                      ),
                                      hintText:
                                          "Send a message to everyone here",
                                      hintStyle: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 15, bottom: 15, left: 15),
                                child: Text(
                                  "mee-ting-cod",
                                  style: TextStyle(
                                    fontFamily: 'Product Sans',
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 15, bottom: 5),
                                child: Text(
                                  "Joining info",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Text(
                                  "meet.google.com/mee-ting-cod",
                                  style: TextStyle(
                                    letterSpacing: -0.3,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: share,
                                icon: Icon(
                                  Icons.share_outlined,
                                  color: Colors.green[900],
                                ),
                                style: ButtonStyle(
                                    overlayColor: MaterialStateProperty.all(
                                        Colors.green[100])),
                                label: Text(
                                  "Share",
                                  style: TextStyle(color: Colors.green[900]),
                                ),
                              ),
                              Divider(
                                color: Colors.grey,
                                thickness: 0.25,
                                indent: 15,
                                height: 0,
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 15, top: 16, bottom: 22),
                                child: Text(
                                  "Attachments (0)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Text(
                                  "Google Calendar attachments will be shown here",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[700]),
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
            ),
          ),
        ],
      ),
    );
  }
}
