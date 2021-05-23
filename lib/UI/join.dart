import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Join extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return JoinState();
  }
}

class JoinState extends State<Join> {
  var clr1 = Colors.green[800];
  var clr2 = Colors.transparent;
  var clr3 = Colors.transparent;
  var icon = Icons.volume_up_outlined;
  var isMicPressed = false;
  var isVidPressed = false;
  User _user = FirebaseAuth.instance.currentUser;
  CameraController _controller;

  @override
  void initState() {
    super.initState();
    camera();
  }

  void camera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras.first, ResolutionPreset.max);
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
              SizedBox(height: 7,),
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
                  color: clr1,
                ),
              ),
              ListTile(
                dense: true,
                onTap: phone,
                leading: Icon(
                  Icons.phone_in_talk,
                  color: Colors.black54,
                ),
                title: Text(
                  "Phone",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                trailing: Icon(
                  Icons.check,
                  color: clr2,
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
                  color: clr3,
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
            ],
          );
        });
  }

  void askToJoin() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              icon,
              color: Colors.white,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Stack(
            children: [
              isVidPressed
                  ? _user != null
                      ? Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height - 160,
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
                              height: MediaQuery.of(context).size.height - 160,
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
                      height: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            color: Colors.white,
            height: 160,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    "mee-ting-cod",
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
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
                    primary: Colors.green[900],
                    onPrimary: Colors.green[900],
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
    );
  }
}
