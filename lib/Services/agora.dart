import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gmeet/UI/home.dart';

class Agora {
  final _appId = "6d4aa2fdccfd43438c4c811d12f16141";
  final _token =
      "0066d4aa2fdccfd43438c4c811d12f16141IACvpXwkueKx4BEuyP4+cdD8YYrnhVrujJP67rRfyrvkwM7T9ukAAAAAEADIUmqkPZi/YAEAAQA9mL9g";
  RtcEngine engine;
  String channel = "";
  List<String> users = [
    FirebaseAuth.instance.currentUser.displayName + ' (You)'
  ];
  List<String> messages = [];
  List<String> messageUsers = [];
  List<String> messageTime = [];

  joinChannel(BuildContext context) async {
    RtcEngineConfig config = RtcEngineConfig(_appId);
    engine = await RtcEngine.createWithConfig(config);

    engine.setEventHandler(RtcEngineEventHandler(
        joinChannelSuccess: (channel, uid, elapsed) {
          this.channel = channel;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("You joined $channel"),
              duration: Duration(milliseconds: 1000),
            ),
          );
        },
        error: (errorCode) {
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

    await engine.joinChannel(_token, "meet", null, 0);
  }
}
