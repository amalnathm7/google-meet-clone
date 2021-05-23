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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Stack(
            children: [
              Column(
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
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
