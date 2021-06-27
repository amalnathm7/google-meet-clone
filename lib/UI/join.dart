import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gmeet/Services/agora.dart';
import 'package:gmeet/UI/home.dart';

class Join extends StatefulWidget {
  Join({this.code, this.agora});

  final String code;
  final Agora agora;

  @override
  State<StatefulWidget> createState() {
    return JoinState(code: code, agora: agora);
  }
}

class JoinState extends State<Join> {
  JoinState({this.code, this.agora});

  final String code;
  final Agora agora;
  User _user = FirebaseAuth.instance.currentUser;
  CameraController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    agora.addListener(_callback);
    camera();
  }

  void _callback() {
    setState(() {
      _loading = false;
    });
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
    agora.removeListener(_callback);
    _controller?.dispose();
    super.dispose();
  }

  void mic() {
    setState(() {
      HomeState.isMuted = !HomeState.isMuted;
      Fluttertoast.cancel();
    });
    Fluttertoast.showToast(
      msg: HomeState.isMuted ? "Microphone off" : "Microphone on",
      gravity: ToastGravity.CENTER,
      textColor: Colors.white,
      backgroundColor: Colors.transparent,
    );
  }

  void video() {
    setState(() {
      HomeState.isVidOff = !HomeState.isVidOff;
    });
  }

  void speaker() {
    setState(() {
      HomeState.clr1 = Colors.teal[700];
      HomeState.clr2 = Colors.transparent;
      HomeState.clr3 = Colors.transparent;
      HomeState.soundIcon = Icons.volume_up_outlined;
    });
    Navigator.pop(context);
  }

  void phone() {
    setState(() {
      HomeState.clr2 = Colors.teal[700];
      HomeState.clr1 = Colors.transparent;
      HomeState.clr3 = Colors.transparent;
      HomeState.soundIcon = HomeState.isHeadphoneConnected
          ? Icons.headset_outlined
          : Icons.phone_in_talk;
    });
    Navigator.pop(context);
  }

  void audioOff() {
    setState(() {
      HomeState.clr3 = Colors.teal[700];
      HomeState.clr2 = Colors.transparent;
      HomeState.clr1 = Colors.transparent;
      HomeState.soundIcon = Icons.volume_off_outlined;
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
              SizedBox(
                height: 8,
              ),
              ListTile(
                dense: true,
                onTap: speaker,
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
                dense: true,
                onTap: phone,
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
                dense: true,
                onTap: audioOff,
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
                dense: true,
                onTap: () {
                  Navigator.pop(context);
                },
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

  void askToJoin() async {
    setState(() {
      agora.askingToJoin = true;
    });
    await agora.askToJoin(code);
  }

  void cancel() async {
    await agora.cancelAskToJoin(code);
    Navigator.pop(context);
  }

  void join() async {
    setState(() {
      _loading = true;
    });
    await agora.joinExistingChannel(code);
  }

  void present() async {}

  @override
  Widget build(BuildContext context) {
    agora.context = context;
    return Opacity(
      opacity: _loading ? 0.5 : 1,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          automaticallyImplyLeading: false,
          actions: <Widget>[
            IconButton(
              onPressed: btm,
              splashRadius: 25,
              splashColor: Colors.transparent,
              icon: Icon(
                HomeState.soundIcon,
                color: Colors.white,
              ),
            )
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      HomeState.isVidOff
                          ? _user != null
                              ? Container(
                                  child: Center(
                                    child: ClipRRect(
                                      child: Image.network(
                                        _user.photoURL,
                                        height: 80,
                                      ),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                  ),
                                )
                              : SizedBox()
                          : _controller != null
                              ? _controller.value.isInitialized
                                  ? Container(
                                      width: MediaQuery.of(context).size.width,
                                      height:
                                          MediaQuery.of(context).size.height -
                                              160,
                                      child: CameraPreview(_controller),
                                    )
                                  : SizedBox()
                              : SizedBox(),
                      Positioned(
                        bottom: 0,
                        left: (MediaQuery.of(context).size.width - 150) / 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
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
                                  width: 40,
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
                            SizedBox(
                              height: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  height: agora.isAlreadyAccepted || agora.isHost ? 180 : 160,
                  width: MediaQuery.of(context).size.width,
                  child: agora.askingToJoin
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                "Asking to join...",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 18),
                              ),
                            ),
                            Text(
                                "You'll join the meeting when someone lets you in"),
                            SizedBox(
                              height: 10,
                            ),
                            MaterialButton(
                              animationDuration: Duration(milliseconds: 0),
                              elevation: 0,
                              textColor: Colors.teal[800],
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontFamily: 'Product Sans',
                                ),
                              ),
                              splashColor: Colors.transparent,
                              onPressed: cancel,
                              padding: EdgeInsets.only(left: 20, right: 20),
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      color: Colors.grey[300], width: 1),
                                  borderRadius: BorderRadius.circular(3)),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Text(
                                code,
                                style: TextStyle(
                                    color: Colors.black, fontSize: 18),
                              ),
                            ),
                            agora.isAlreadyAccepted || agora.isHost
                                ? Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10, right: 10),
                                        child: Container(
                                            width: 500,
                                            height: 20,
                                            child: agora.usersHere.isEmpty
                                                ? Text(
                                                    "You're the first one here.",
                                                    textAlign: TextAlign.center,
                                                    overflow: TextOverflow.clip,
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        "On a call: ",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Text(
                                                        agora.usersHere
                                                                    .length ==
                                                                1
                                                            ? agora.usersHere[0]
                                                            : agora.usersHere
                                                                        .length ==
                                                                    2
                                                                ? agora.usersHere[
                                                                        0] +
                                                                    " and " +
                                                                    agora.usersHere[
                                                                        1]
                                                                : agora.usersHere[
                                                                        0] +
                                                                    ", " +
                                                                    agora.usersHere[
                                                                        1] +
                                                                    " and " +
                                                                    (agora.usersHere.length -
                                                                            2)
                                                                        .toString() +
                                                                    " more.",
                                                      )
                                                    ],
                                                  )),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          MaterialButton(
                                            animationDuration:
                                                Duration(milliseconds: 0),
                                            color: Colors.teal[800],
                                            textColor: Colors.white,
                                            elevation: 0,
                                            child: Text(
                                              "Join meeting",
                                              style: TextStyle(
                                                fontFamily: 'Product Sans',
                                              ),
                                            ),
                                            splashColor: Colors.transparent,
                                            onPressed: join,
                                            padding: EdgeInsets.only(
                                                left: 25, right: 25),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(3)),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          MaterialButton(
                                            animationDuration:
                                                Duration(milliseconds: 0),
                                            elevation: 0,
                                            textColor: Colors.teal[800],
                                            child: Text(
                                              "Present",
                                              style: TextStyle(
                                                fontFamily: 'Product Sans',
                                              ),
                                            ),
                                            splashColor: Colors.transparent,
                                            onPressed: present,
                                            padding: EdgeInsets.only(
                                                left: 25, right: 25),
                                            shape: RoundedRectangleBorder(
                                                side: BorderSide(
                                                    color: Colors.grey[300],
                                                    width: 1),
                                                borderRadius:
                                                    BorderRadius.circular(3)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : ElevatedButton(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      child: Text(
                                        "Ask to join",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Product Sans',
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    onPressed: askToJoin,
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      primary: Colors.teal[800],
                                      onPrimary: Colors.teal[800],
                                      shadowColor: Colors.transparent,
                                    ),
                                  ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Joining as",
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _user != null
                                    ? ClipRRect(
                                        child: Image.network(
                                          _user.photoURL,
                                          height: 20,
                                        ),
                                        borderRadius: BorderRadius.circular(50),
                                      )
                                    : SizedBox(),
                                Text("  " + _user?.email)
                              ],
                            )
                          ],
                        ),
                )
              ],
            ),
            _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.teal[800],
                    ),
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
