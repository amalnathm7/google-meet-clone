import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gmeet/UI/home.dart';

class Agora {
  final appId = "6d4aa2fdccfd43438c4c811d12f16141";
  final token =
      "0066d4aa2fdccfd43438c4c811d12f16141IAClhhGqlogwU9Hx0NRRDHG9CCZ+S/z2Ltjc/XdU+rIWX87T9ukAAAAAEADGEkMQUoO7YAEAAQBRg7tg";
  RtcEngine engine;
  List<String> users = [
    FirebaseAuth.instance.currentUser.displayName + ' (You)'
  ];
  List<String> messages = [];
  List<String> messageUsers = [];
  List<String> messageTime = [];

  joinChannel(BuildContext context) async {
    RtcEngineConfig config = RtcEngineConfig(appId);
    engine = await RtcEngine.createWithConfig(config);

    engine.setEventHandler(RtcEngineEventHandler(error: (errorCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error : $errorCode"),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }, userJoined: (uid, elapsed) {
      users.add(uid.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$uid joined this meeting"),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }, userOffline: (int uid, UserOfflineReason reason) {
      users.remove(uid.toString());
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

    await engine.joinChannel(token, "meet", null, 0);
  }
}
