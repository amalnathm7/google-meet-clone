import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gmeet/Services/agora.dart';
import 'package:gmeet/UI/home.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class Live extends StatefulWidget {
  final Agora agora;

  Live({this.agora});

  @override
  State<StatefulWidget> createState() {
    return LiveState(agora: agora);
  }
}

class LiveState extends State<Live>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  LiveState({this.agora});

  double _opacity = 0.0;
  double _bottom = -60.0;
  double _position;
  int _currentIndex = 0;
  int _pin = -1;
  bool _capPressed = false;
  bool offed = false;
  TextEditingController _textEditingController = TextEditingController();
  Timer _timer = Timer(Duration(seconds: 0), null);
  Timer _timer2;
  TabController _tabController;
  Agora agora;
  StreamSubscription<ConnectivityResult> subscription;

  @override
  void initState() {
    super.initState();
    agora.addListener(_callback);
    _singleTap();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.animation.addListener(() {
      setState(() {
        _currentIndex = _tabController.animation.value.round();
        if (_currentIndex != 1) {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        } else {
          agora.msgCount = 0;
        }
      });
    });
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No Internet connection"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (agora.isHost && agora.meetCreated) _showDialog();
      _position = MediaQuery.of(context).size.width * 2 / 3;
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer.cancel();
    _timer2?.cancel();
    _tabController.dispose();
    _textEditingController.dispose();
    agora.removeListener(_callback);
    agora.exitMeeting();
    agora.engine.destroy();
    subscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (!HomeState.isVidOff) {
        _video();
        offed = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (offed) _video();
      _singleTap();
    }
    super.didChangeAppLifecycleState(state);
  }

  void _callback() {
    setState(() {
      if (_pin >= agora.userNames.length) _pin = -1;
      if (agora.currentUserIndex >= agora.userNames.length)
        agora.currentUserIndex = 0;
      if (_currentIndex == 1) agora.msgCount = 0;
    });
  }

  _showDialog() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 10),
            titlePadding: EdgeInsets.only(left: 24, right: 10, top: 24),
            title: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Share this to invite others",
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey[700],
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
            titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                letterSpacing: 0.3,
                fontFamily: 'Product Sans'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Share this info with people that you want to meet with. "
                  "Make sure that you save it somewhere if you plan to meet later.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(
                  height: 25,
                ),
                Text(
                  "Meeting code: " + agora.code,
                  style: TextStyle(fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: _share,
                  icon: Icon(
                    Icons.share_outlined,
                    color: Colors.teal[700],
                  ),
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all(
                          EdgeInsets.only(left: 3, right: 3)),
                      overlayColor: MaterialStateProperty.all(Colors.teal[50])),
                  label: Text(
                    "Share",
                    style: TextStyle(color: Colors.teal[700]),
                  ),
                ),
              ],
            ),
          );
        });
  }

  void _mic() {
    setState(() {
      HomeState.isMuted = !HomeState.isMuted;
      agora.usersMuted.setAll(0, [HomeState.isMuted]);
      Fluttertoast.cancel();
    });
    agora.engine.muteLocalAudioStream(HomeState.isMuted);
    agora.muteAudio(HomeState.isMuted);
    Fluttertoast.showToast(
      msg: HomeState.isMuted ? "Microphone off" : "Microphone on",
      gravity: ToastGravity.TOP,
      textColor: Colors.white,
      backgroundColor: Colors.transparent,
    );
  }

  void _video() {
    setState(() {
      HomeState.isVidOff = !HomeState.isVidOff;
      agora.usersVidOff.setAll(0, [HomeState.isVidOff]);
    });
    agora.engine.muteLocalVideoStream(HomeState.isVidOff);
    agora.muteVideo(HomeState.isVidOff);
  }

  void _end() async {
    await agora.engine.leaveChannel();
    Navigator.pop(context);
    await agora.exitMeeting();
  }

  void _singleTap() {
    _timer.cancel();
    setState(() {
      if (_opacity == 0) {
        _opacity = 1;
        _bottom = 20;
        _timer = Timer(Duration(seconds: 5), _btnFade);
      } else {
        _opacity = 0;
        _bottom = -60;
      }
    });
  }

  void _btnFade() {
    if (_opacity != 0)
      setState(() {
        _opacity = 0;
        _bottom = -60;
      });
  }

  void _doubleTap() {}

  void _speaker() {
    agora.engine.muteAllRemoteAudioStreams(false);
    setState(() {
      HomeState.clr1 = Colors.teal[700];
      HomeState.clr2 = Colors.transparent;
      HomeState.clr3 = Colors.transparent;
      HomeState.soundIcon = Icons.volume_up_outlined;
    });
    Navigator.pop(context);
  }

  void _phone() {
    agora.engine.muteAllRemoteAudioStreams(false);
    setState(() {
      HomeState.clr2 = Colors.teal[700];
      HomeState.clr1 = Colors.transparent;
      HomeState.clr3 = Colors.transparent;
      HomeState.soundIcon = HomeState.isHeadphoneConnected
          ? Icons.headset_outlined
          : Icons.volume_up_outlined;
    });
    Navigator.pop(context);
  }

  void _audioOff() {
    agora.engine.muteAllRemoteAudioStreams(true);
    setState(() {
      HomeState.clr3 = Colors.teal[700];
      HomeState.clr2 = Colors.transparent;
      HomeState.clr1 = Colors.transparent;
      HomeState.soundIcon = Icons.volume_off_outlined;
    });
    Navigator.pop(context);
  }

  void _vol() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 8,
              ),
              ListTile(
                onTap: _speaker,
                dense: true,
                leading: Icon(
                  Icons.volume_up_outlined,
                  color: Colors.black54,
                ),
                title: Text(
                  "Speaker",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                trailing: Icon(
                  Icons.check,
                  color: HomeState.clr1,
                ),
              ),
              ListTile(
                onTap: _phone,
                dense: true,
                leading: Icon(
                  HomeState.isHeadphoneConnected
                      ? Icons.headset_outlined
                      : Icons.phone_in_talk,
                  color: Colors.black54,
                ),
                title: Text(
                  HomeState.isHeadphoneConnected ? "Wired headphones" : "Phone",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                trailing: Icon(
                  Icons.check,
                  color: HomeState.clr2,
                ),
              ),
              ListTile(
                onTap: _audioOff,
                dense: true,
                leading: Icon(
                  Icons.volume_off_outlined,
                  color: Colors.black54,
                ),
                title: Text(
                  "Audio off",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
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
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(
                height: 8,
              )
            ],
          );
        });
  }

  void _captions() {
    setState(() {
      _capPressed = !_capPressed;
    });
    if (_capPressed)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Captions are being turned on"),
          duration: Duration(milliseconds: 1000),
        ),
      );
  }

  void _switchCamera() {
    Navigator.pop(context);
    agora.engine.switchCamera();
  }

  void _present() {
    Navigator.pop(context);
  }

  void _reportProblem() async {
    Navigator.pop(context);
    const _url = 'mailto:amalnathm7@gmail.com?subject=Feedback';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void _reportAbuse() async {
    Navigator.pop(context);
    const _url = 'https://support.google.com/meet/contact/abuse';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void _help() async {
    Navigator.pop(context);
    const _url = 'https://support.google.com';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void _moreOptions() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: _switchCamera,
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
                  _captions();
                },
                horizontalTitleGap: 3,
                leading: Icon(
                  _capPressed ? Icons.closed_caption : Icons.closed_caption_off,
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
                onTap: _present,
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
                onTap: _reportProblem,
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
                onTap: _reportAbuse,
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
                onTap: _help,
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

  void _sendMsg() async {
    setState(() {
      agora.msgSentReceived.insert(0, false);
    });

    if (_timer2 != null &&
        _timer2.isActive &&
        agora.messageId[0] == FirebaseAuth.instance.currentUser.uid) {
      agora.messageId.insert(0, FirebaseAuth.instance.currentUser.uid);
      agora.messageUsers.insert(0, "");
      agora.messageTime.insert(0, "");
      agora.messages.insert(0, _textEditingController.text);
    } else {
      agora.messageId.insert(0, FirebaseAuth.instance.currentUser.uid);
      agora.messageUsers.insert(0, "You");
      agora.messageTime.insert(0, "Now");
      agora.messages.insert(0, _textEditingController.text);
    }

    String temp = _textEditingController.text;

    _textEditingController.clear();

    await agora.sendMessage(temp);

    setState(() {
      agora.msgSentReceived[0] = true;
    });

    if (agora.messageTime[0].isNotEmpty) {
      var length = agora.messageTime.length;
      var time = DateFormat('hh:mm a').format(DateTime.now());
      var i = 1;

      _timer2 = Timer(Duration(seconds: 45), () {});

      Timer.periodic(Duration(minutes: 1), (timer) {
        if (i == 31 && mounted) {
          setState(() {
            agora.messageTime.setAll(agora.messageTime.length - length, [time]);
          });
          timer.cancel();
        } else if (mounted)
          setState(() {
            agora.messageTime.setAll(
                agora.messageTime.length - length, [(i).toString() + " min"]);
            i++;
          });
        else
          timer.cancel();
      });
    }

    await agora.deleteMessage();
  }

  removeUser(int index) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              "Remove " + agora.userNames[index] + " from this video call?",
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            contentPadding:
                EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 0),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                        color: Colors.teal[800],
                        fontSize: 14,
                        fontFamily: 'Product Sans'),
                  )),
              TextButton(
                  onPressed: () async {
                    await agora.removeUser(index);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Remove",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.teal[800],
                        fontFamily: 'Product Sans'),
                  )),
            ],
          );
        });
  }

  muteUser(int index) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              "Mute " +
                  agora.userNames[index] +
                  " for everyone in the meeting? To protect their privacy, only " +
                  agora.userNames[index] +
                  " can unmute themselves.",
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            contentPadding:
                EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 0),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                        color: Colors.teal[800],
                        fontSize: 14,
                        fontFamily: 'Product Sans'),
                  )),
              TextButton(
                  onPressed: () async {
                    await agora.muteUser(index);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Mute",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.teal[800],
                        fontFamily: 'Product Sans'),
                  )),
            ],
          );
        });
  }

  void _share() async {
    await Share.share("Join my meeting using the code: " +
        agora.code +
        "\n\nApp link: https://");
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
            onTap: _singleTap,
            onDoubleTap: _doubleTap,
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
                    child: agora.usersVidOff.length > _pin &&
                            agora.usersVidOff.length > agora.currentUserIndex
                        ? agora.usersVidOff[
                                _pin != -1 ? _pin : agora.currentUserIndex]
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 50,
                                  ),
                                  ClipRRect(
                                    child: Image.network(
                                      agora.userImages[_pin != -1
                                          ? _pin
                                          : agora.currentUserIndex],
                                      height: 80,
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  AnimatedOpacity(
                                    opacity: 1 - _opacity,
                                    duration: Duration(milliseconds: 300),
                                    child: Text(
                                      agora.userNames[_pin != -1
                                          ? _pin
                                          : agora.currentUserIndex],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _pin == 0
                                ? RtcLocalView.SurfaceView()
                                : agora.userUIDs.length > _pin &&
                                        agora.userUIDs.length >
                                            agora.currentUserIndex
                                    ? RtcRemoteView.SurfaceView(
                                        uid: agora.userUIDs[_pin != -1
                                            ? _pin
                                            : agora.currentUserIndex],
                                      )
                                    : SizedBox()
                        : SizedBox()),
                Positioned(
                  top: 40,
                  right: 0,
                  child: AnimatedOpacity(
                    curve: Curves.easeIn,
                    opacity: _opacity,
                    duration: Duration(milliseconds: 200),
                    child: Container(
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(HomeState.soundIcon),
                            onPressed: _opacity == 0 ? null : _vol,
                            color: Colors.white,
                            highlightColor: Colors.white10,
                            splashRadius: 25,
                          ),
                          IconButton(
                            icon: Icon(_capPressed
                                ? Icons.closed_caption
                                : Icons.closed_caption_off),
                            onPressed: _opacity == 0 ? null : _captions,
                            color: Colors.white,
                          ),
                          IconButton(
                            icon: Icon(Icons.more_horiz),
                            onPressed: _opacity == 0 ? null : _moreOptions,
                            color: Colors.white,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  bottom: _bottom,
                  left: (MediaQuery.of(context).size.width - 215) / 2,
                  curve: Curves.easeInOut,
                  duration: Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            height: 55,
                            width: 55,
                            duration: Duration(milliseconds: 200),
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
                              onPressed: _mic,
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
                              onPressed: _end,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(
                            width: 25,
                          ),
                          AnimatedContainer(
                            height: 55,
                            width: 55,
                            duration: Duration(milliseconds: 200),
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
                              onPressed: _video,
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
                          indicatorColor: Colors.teal[700],
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.label,
                          overlayColor:
                              MaterialStateProperty.all(Colors.teal[100]),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _currentIndex == 0
                                        ? Icons.people_alt
                                        : Icons.people_alt_outlined,
                                    color: _currentIndex == 0
                                        ? Colors.teal[700]
                                        : Colors.grey[700],
                                  ),
                                  Text(
                                    ' (' +
                                        agora.userNames.length.toString() +
                                        ')',
                                    style: TextStyle(
                                      color: _currentIndex == 0
                                          ? Colors.teal[700]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              child: Container(
                                height: agora.msgCount == 0 ? 30 : 50,
                                width: agora.msgCount == 0 ? 30 : 50,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        _currentIndex == 1
                                            ? Icons.messenger_outlined
                                            : Icons.message_outlined,
                                        color: _currentIndex == 1
                                            ? Colors.teal[700]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    agora.msgCount == 0
                                        ? SizedBox()
                                        : Positioned(
                                            right: 5,
                                            top: 5,
                                            child: Container(
                                              height: 16,
                                              width:
                                                  agora.msgCount > 9 ? 22 : 16,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Colors.teal[800],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  agora.msgCount > 99
                                                      ? "99+"
                                                      : agora.msgCount
                                                          .toString(),
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          )
                                  ],
                                ),
                              ),
                            ),
                            Tab(
                              icon: Icon(
                                _currentIndex == 2
                                    ? Icons.info
                                    : Icons.info_outline,
                                color: _currentIndex == 2
                                    ? Colors.teal[700]
                                    : Colors.grey[700],
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
                              itemCount: agora.userNames.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: 70,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            color: Colors.grey[200],
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                3,
                                            child: Stack(
                                              children: [
                                                Center(
                                                  child: ClipRRect(
                                                    child: Image.network(
                                                      agora.userImages[index],
                                                      height: 50,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Opacity(
                                              opacity: _pin != -1
                                                  ? _pin == index
                                                      ? 0.7
                                                      : 0
                                                  : agora.currentUserIndex ==
                                                          index
                                                      ? 0.7
                                                      : 0,
                                              child: Container(
                                                color: Colors.black,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    3,
                                              )),
                                          Positioned(
                                              top: 20,
                                              left: (MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          3 -
                                                      30) /
                                                  2,
                                              child: Icon(
                                                _pin == index
                                                    ? Icons.push_pin
                                                    : null,
                                                color: Colors.white,
                                                size: 30,
                                              )),
                                          Positioned(
                                            right:
                                                agora.usersMuted[index] ? 5 : 3,
                                            bottom:
                                                agora.usersMuted[index] ? 5 : 0,
                                            child: Container(
                                                child: Padding(
                                                  padding:
                                                      agora.usersMuted[index]
                                                          ? EdgeInsets.all(3.0)
                                                          : EdgeInsets.zero,
                                                  child: Icon(
                                                    agora.usersMuted[index]
                                                        ? Icons.mic_off
                                                        : Icons
                                                            .more_horiz_rounded,
                                                    color: agora
                                                            .usersMuted[index]
                                                        ? Colors.white
                                                        : _pin != -1
                                                            ? _pin == index
                                                                ? Colors
                                                                    .tealAccent
                                                                : Colors.teal
                                                            : agora.currentUserIndex ==
                                                                    index
                                                                ? Colors
                                                                    .tealAccent
                                                                : Colors.teal,
                                                    size:
                                                        agora.usersMuted[index]
                                                            ? 18
                                                            : 28,
                                                  ),
                                                ),
                                                decoration: BoxDecoration(
                                                  color: agora.usersMuted[index]
                                                      ? Colors.red[800]
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                )),
                                          ),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  if (_pin == index)
                                                    _pin = -1;
                                                  else
                                                    _pin = index;
                                                });
                                              },
                                              splashColor: Colors.white24,
                                              child: Ink(
                                                height: 70,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Stack(
                                        children: [
                                          Center(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 14),
                                              child:
                                                  Text(agora.userNames[index]),
                                            ),
                                          ),
                                          index != 0
                                              ? Positioned(
                                                  child: Icon(
                                                    Icons.keyboard_arrow_right,
                                                    color: Colors.grey[700],
                                                  ),
                                                  height: 70,
                                                  right: 8,
                                                )
                                              : SizedBox(),
                                          index != 0
                                              ? Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        _position = 0;
                                                      });
                                                    },
                                                    splashColor: Colors.white24,
                                                    child: Ink(
                                                      height: 70,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              2 /
                                                              3,
                                                    ),
                                                  ),
                                                )
                                              : SizedBox(),
                                          index != 0
                                              ? AnimatedPositioned(
                                                  duration: Duration(
                                                      milliseconds: 200),
                                                  curve: Curves.easeInOut,
                                                  height: 70,
                                                  left: _position,
                                                  child: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            2 /
                                                            3,
                                                    color: Colors.teal[700],
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          height: 70,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          child: IconButton(
                                                              icon: Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _position = MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      2 /
                                                                      3;
                                                                });
                                                              }),
                                                        ),
                                                        Container(
                                                          height: 70,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                        10),
                                                                bottomLeft: Radius
                                                                    .circular(
                                                                        10)),
                                                          ),
                                                          child: IconButton(
                                                            icon: Icon(
                                                              _pin == index
                                                                  ? Icons
                                                                      .push_pin
                                                                  : Icons
                                                                      .push_pin_outlined,
                                                              color: _pin ==
                                                                      index
                                                                  ? Colors
                                                                      .teal[700]
                                                                  : Colors.grey[
                                                                      700],
                                                            ),
                                                            splashColor:
                                                                Colors.grey,
                                                            onPressed: () {
                                                              setState(() {
                                                                if (_pin ==
                                                                    index)
                                                                  _pin = -1;
                                                                else
                                                                  _pin = index;
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        Container(
                                                          height: 70,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          color: Colors.white,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .mic_off_outlined,
                                                            ),
                                                            color: Colors
                                                                .grey[700],
                                                            splashColor:
                                                                Colors.grey,
                                                            onPressed: agora
                                                                        .isHost &&
                                                                    !agora.usersMuted[
                                                                        index]
                                                                ? () {
                                                                    muteUser(
                                                                        index);
                                                                  }
                                                                : null,
                                                          ),
                                                        ),
                                                        Container(
                                                          height: 70,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              6,
                                                          color: Colors.white,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .remove_circle_outline,
                                                            ),
                                                            splashColor:
                                                                Colors.grey,
                                                            disabledColor:
                                                                Colors.grey,
                                                            color: Colors
                                                                .grey[700],
                                                            onPressed:
                                                                agora.isHost
                                                                    ? () {
                                                                        removeUser(
                                                                            index);
                                                                      }
                                                                    : null,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              : SizedBox(),
                                        ],
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
                                      itemCount: agora.messages.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: agora.messageTime[index]
                                                        .isEmpty
                                                    ? 0
                                                    : 20,
                                              ),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  agora.messageUsers[index]
                                                          .isEmpty
                                                      ? SizedBox()
                                                      : Text(
                                                          agora.messageUsers[
                                                              index],
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                  SizedBox(
                                                    width: agora
                                                            .messageTime[index]
                                                            .isEmpty
                                                        ? 0
                                                        : 8,
                                                  ),
                                                  agora.messageTime[index]
                                                          .isEmpty
                                                      ? SizedBox()
                                                      : Text(
                                                          agora.messageTime[
                                                              index],
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey[700],
                                                          ),
                                                        ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 3,
                                              ),
                                              Text(
                                                agora.messages[index],
                                                style: TextStyle(
                                                    color:
                                                        agora.msgSentReceived[
                                                                index]
                                                            ? Colors.black
                                                            : Colors.grey),
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border(
                                          top: BorderSide(
                                              width: 1.25,
                                              color: Colors.grey[300]))),
                                  child: TextField(
                                    controller: _textEditingController,
                                    onChanged: (text) {
                                      setState(() {});
                                    },
                                    onSubmitted: (text) {
                                      setState(() {});
                                    },
                                    cursorColor: Colors.teal[800],
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    style: TextStyle(fontSize: 13),
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.only(
                                            left: 15,
                                            right: 15,
                                            bottom: 15,
                                            top: 20),
                                        suffixIcon: Padding(
                                          padding: const EdgeInsets.only(
                                              top: 5, right: 5),
                                          child: IconButton(
                                            icon: Icon(Icons.send),
                                            iconSize: 22,
                                            color: Colors.teal[800],
                                            splashRadius: 25,
                                            onPressed: _textEditingController
                                                    .text.isEmpty
                                                ? null
                                                : _sendMsg,
                                          ),
                                        ),
                                        hintText:
                                            "Send a message to everyone here",
                                        hintStyle: TextStyle(fontSize: 13.5)),
                                  ),
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
                                  agora.code,
                                  style: TextStyle(
                                    fontFamily: 'Product Sans',
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 15, bottom: 5),
                                child: Text(
                                  "Joining info",
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Text(
                                  "Meeting code : " + agora.code,
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 5, top: 3),
                                child: TextButton.icon(
                                  onPressed: _share,
                                  icon: Icon(
                                    Icons.share_outlined,
                                    color: Colors.teal[700],
                                  ),
                                  style: ButtonStyle(
                                      overlayColor: MaterialStateProperty.all(
                                          Colors.teal[50])),
                                  label: Text(
                                    "Share",
                                    style: TextStyle(color: Colors.teal[700]),
                                  ),
                                ),
                              ),
                              Divider(
                                color: Colors.grey[300],
                                thickness: 1.25,
                                indent: 15,
                                height: 0,
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 15, top: 16, bottom: 22),
                                child: Text(
                                  "Attachments (0)",
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Text(
                                  "Google Calendar attachments will be shown here",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
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
