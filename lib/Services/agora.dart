import 'dart:math';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gmeet/UI/home.dart';
import 'package:gmeet/UI/live.dart';

class Agora {
  final _appId = "6d4aa2fdccfd43438c4c811d12f16141";
  final _token =
      "0066d4aa2fdccfd43438c4c811d12f16141IABezHUOGfnNFmocEdUYrhg9Q15EspOptUE6WjEBynveNs7T9ukAAAAAEADGEkMQY+zAYAEAAQBj7MBg";
  RtcEngine engine;
  String uid;
  List<String> userUIDs = [];
  List<String> userImages = [FirebaseAuth.instance.currentUser.photoURL];
  List<String> userNames = [
    FirebaseAuth.instance.currentUser.displayName + ' (You)'
  ];
  List<bool> ifUserMuted = [HomeState.isMuted];
  List<bool> ifUserVideoOff = [HomeState.isVidOff];
  List<String> messages = [];
  List<String> messageUsers = [];
  List<String> messageTime = [];
  final _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  String code = "meet";
  DocumentSnapshot document;

  createChannel(BuildContext context, HomeState homeState) async {
    //const _chars = 'abcdefghijklmnopqrstuvwxyz';
    //Random _rnd = Random.secure();
    /*code = String.fromCharCodes(Iterable.generate(
        10, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
    code = code.substring(0, 3) +
        '-' +
        code.substring(3, 7) +
        '-' +
        code.substring(7, 10);*/

    await joinCreatedChannel(context, code, homeState);
  }

  joinCreatedChannel(BuildContext context, String channel, HomeState homeState) async {
    RtcEngineConfig config = RtcEngineConfig(_appId);
    engine = await RtcEngine.createWithConfig(config);

    engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) async {
        this.uid = uid.toString();
        userUIDs.add(uid.toString());
        await createMeetingInDB();

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Live(
                      agora: this,
                    )));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You joined $channel"),
            duration: Duration(milliseconds: 1000),
          ),
        );
        homeState.stopLoading();
      },
      error: (errorCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error : $errorCode"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      userJoined: (uid, elapsed) async {
        DocumentSnapshot snap = await FirebaseFirestore.instance
            .collection("meetings")
            .doc(code)
            .collection("users")
            .doc(uid.toString())
            .get();

        userUIDs.add(uid.toString());
        userNames.add(snap.get('name'));
        userImages.add(snap.get('image_url'));
        ifUserMuted.add(snap.get('isMuted'));
        ifUserVideoOff.add(snap.get('isVidOff'));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$uid joined this meeting"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      userOffline: (int uid, UserOfflineReason reason) {
        int index = userUIDs.indexOf(uid.toString());
        userUIDs.removeAt(index);
        userNames.removeAt(index);
        userImages.removeAt(index);
        ifUserVideoOff.removeAt(index);
        ifUserMuted.removeAt(index);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$uid left this meeting"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      remoteAudioStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid.toString());
        ifUserMuted
            .setAll(index, [reason == AudioRemoteStateReason.RemoteMuted]);
      },
      remoteVideoStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid.toString());
        ifUserVideoOff
            .setAll(index, [reason == VideoRemoteStateReason.RemoteMuted]);
      },
    ));

    await engine.enableVideo();
    await engine.enableAudio();

    await engine.muteLocalAudioStream(HomeState.isMuted);
    await engine.muteLocalVideoStream(HomeState.isVidOff);

    await engine.joinChannel(_token, channel, null, 0);
  }

  createMeetingInDB() async {
    await _db.collection("meetings").doc(code).set({
      'host': _user.uid,
      'token':
          "0066d4aa2fdccfd43438c4c811d12f16141IABAanD8QludZe0NlduEoYUHG39o6s4m9wq+t5zskrcddM7T9ukAAAAAEAAg7xFxTeW4YAEAAQD1l7hg"
    });

    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(uid)
        .set({
      'name': _user.displayName,
      'image_url': _user.photoURL,
      'isMuted': HomeState.isMuted,
      'isVidOff': HomeState.isVidOff
    });

    await _db
        .collection("meetings")
        .doc(code)
        .collection("messages")
        .doc("messages")
        .set({});
  }

  Future<bool> ifMeetingExists(String code) async {
    document = await _db.collection("meetings").doc(code).get();
    if (document.exists) return true;
    return false;
  }

  joinExistingChannel(BuildContext context, String channel) async {
    RtcEngineConfig config = RtcEngineConfig(_appId);
    engine = await RtcEngine.createWithConfig(config);

    engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) async {
        this.code = channel;
        this.uid = uid.toString();
        userUIDs.add(uid.toString());
        await joinMeetingInDB(channel);

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Live(
                      agora: this,
                    )));

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
      },
      userJoined: (uid, elapsed) async {
        DocumentSnapshot snap = await FirebaseFirestore.instance
            .collection("meetings")
            .doc(code)
            .collection("users")
            .doc(uid.toString())
            .get();

        userUIDs.add(uid.toString());
        userNames.add(snap.get('name'));
        userImages.add(snap.get('image_url'));
        ifUserMuted.add(snap.get('isMuted'));
        ifUserVideoOff.add(snap.get('isVidOff'));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$uid joined this meeting"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      userOffline: (int uid, UserOfflineReason reason) {
        int index = userUIDs.indexOf(uid.toString());
        userUIDs.removeAt(index);
        userNames.removeAt(index);
        userImages.removeAt(index);
        ifUserVideoOff.removeAt(index);
        ifUserMuted.removeAt(index);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$uid left this meeting"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      remoteAudioStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid.toString());
        ifUserMuted
            .setAll(index, [reason == AudioRemoteStateReason.RemoteMuted]);
      },
      remoteVideoStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid.toString());
        ifUserVideoOff
            .setAll(index, [reason == VideoRemoteStateReason.RemoteMuted]);
      },
    ));

    await engine.enableVideo();
    await engine.enableAudio();

    await engine.muteLocalAudioStream(HomeState.isMuted);
    await engine.muteLocalVideoStream(HomeState.isVidOff);

    await engine.joinChannel(_token, channel, null, 0);
  }

  joinMeetingInDB(String code) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(uid)
        .set({
      'name': _user.displayName,
      'image_url': _user.photoURL,
      'isMuted': HomeState.isMuted,
      'isVidOff': HomeState.isVidOff
    }, SetOptions(merge: false));
  }

  sendMessage(String msg, String code) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("messages")
        .doc("messages")
        .update({
      DateTime.now().toString().substring(0, 19) +
          ":" +
          DateTime.now().millisecond.toString(): {_user.displayName: msg}
    });
  }

  toggleMic(String code) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(uid)
        .update({
      'isMuted': HomeState.isMuted,
    });
  }

  toggleCam(String code) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(uid)
        .update({
      'isVidOff': HomeState.isVidOff,
    });
  }

  exitMeeting() async {
    await FirebaseFirestore.instance
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(uid)
        .delete();
  }
}
