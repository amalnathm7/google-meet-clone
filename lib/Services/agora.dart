import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gmeet/UI/home.dart';

class Agora {
  final _appId = "6d4aa2fdccfd43438c4c811d12f16141";
  final _token =
      "0066d4aa2fdccfd43438c4c811d12f16141IACvpXwkueKx4BEuyP4+cdD8YYrnhVrujJP67rRfyrvkwM7T9ukAAAAAEADIUmqkPZi/YAEAAQA9mL9g";
  RtcEngine engine;
  String channel = "";
  String uid = "";
  List<String> userUIDs = [];
  List<String> userImages = [FirebaseAuth.instance.currentUser.photoURL];
  List<String> userNames = [
    FirebaseAuth.instance.currentUser.displayName + ' (You)'
  ];
  List<String> messages = [];
  List<String> messageUsers = [];
  List<String> messageTime = [];

  joinChannel(BuildContext context) async {
    RtcEngineConfig config = RtcEngineConfig(_appId);
    engine = await RtcEngine.createWithConfig(config);

    engine.setEventHandler(
        RtcEngineEventHandler(joinChannelSuccess: (channel, uid, elapsed) {
      this.channel = channel;
      this.uid = uid.toString();
      userUIDs.add(uid.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You joined $channel"),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }, error: (errorCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error : $errorCode"),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }, userJoined: (uid, elapsed) async {
      DocumentSnapshot snap = await FirebaseFirestore.instance
          .collection("meetings")
          .doc(channel)
          .collection("users")
          .doc(uid.toString()).get();

      userUIDs.add(uid.toString());
      userNames.add(snap.get('name'));
      userImages.add(snap.get('image_url'));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$uid joined this meeting"),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }, userOffline: (int uid, UserOfflineReason reason) {
      int index = userUIDs.indexOf(uid.toString());
      userUIDs.removeAt(index);
      userNames.removeAt(index);
      userImages.removeAt(index);
      FirebaseFirestore.instance
          .collection("meetings")
          .doc(channel)
          .collection("users")
          .doc(uid.toString())
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$uid left this meeting"),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }));

    await engine.enableVideo();
    await engine.enableAudio();

    engine.muteLocalAudioStream(HomeState.isMuted);
    engine.enableLocalVideo(!HomeState.isVidOff);

    await engine.joinChannel(_token, "meet", null, 0);
  }
}
