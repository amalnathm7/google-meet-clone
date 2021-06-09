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
      "0066d4aa2fdccfd43438c4c811d12f16141IACacGfDSmh56pMVHCq9WTyFe982K+teDvkoxPonI18IPs7T9ukAAAAAEADGEkMQvE3CYAEAAQC9TcJg";
  RtcEngine engine;
  String uid;
  List<String> userUIDs = [];
  List<String> userImages = [FirebaseAuth.instance.currentUser.photoURL];
  List<String> userNames = [
    FirebaseAuth.instance.currentUser.displayName + ' (You)'
  ];
  List<bool> usersMuted = [];
  List<bool> usersVidOff = [];
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

  joinCreatedChannel(
      BuildContext context, String channel, HomeState homeState) async {
    RtcEngineConfig config = RtcEngineConfig(_appId);
    engine = await RtcEngine.createWithConfig(config);

    engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) async {
        await engine.muteLocalAudioStream(HomeState.isMuted);
        await engine.muteLocalVideoStream(HomeState.isVidOff);

        this.uid = uid.toString();

        await createMeetingInDB();

        userUIDs.add(uid.toString());
        usersMuted.add(HomeState.isMuted);
        usersVidOff.add(HomeState.isVidOff);

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
      connectionLost: () {
        exitMeeting();
      },
      connectionStateChanged: (state, reason) {
        if (state == ConnectionStateType.Disconnected) exitMeeting();
      },
      error: (errorCode) {
        exitMeeting();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error : $errorCode"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      userJoined: (uid, elapsed) async {
        int index = userUIDs.indexOf(uid.toString());
        if (index == -1) {
          userUIDs.add(uid.toString());
          usersMuted.add(false);
          usersVidOff.add(false);

          FirebaseFirestore.instance
              .collection("meetings")
              .doc(code)
              .collection("users")
              .doc(uid.toString())
              .snapshots()
              .listen((event) {
            if (userNames.length == userUIDs.length) {
              userNames.setAll(index, [event.get('name')]);
              userImages.setAll(index, [event.get('image_url')]);
            } else {
              userNames.add(event.get('name'));
              userImages.add(event.get('image_url'));
            }
          });
        }

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
        usersVidOff.removeAt(index);
        usersMuted.removeAt(index);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$uid left this meeting"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      remoteAudioStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid.toString());
        usersMuted.setAll(index, [
          state == AudioRemoteState.Stopped &&
              reason == AudioRemoteStateReason.RemoteMuted
        ]);
      },
      remoteVideoStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid.toString());
        usersVidOff.setAll(index, [
          state == VideoRemoteState.Stopped &&
              reason == VideoRemoteStateReason.RemoteMuted
        ]);
      },
    ));

    await engine.enableVideo();
    await engine.enableAudio();

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
        await engine.muteLocalAudioStream(HomeState.isMuted);
        await engine.muteLocalVideoStream(HomeState.isVidOff);

        this.code = channel;
        this.uid = uid.toString();

        await joinMeetingInDB(channel);

        userUIDs.add(uid.toString());
        usersMuted.add(HomeState.isMuted);
        usersVidOff.add(HomeState.isVidOff);

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
        exitMeeting();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error : $errorCode"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      connectionLost: () {
        exitMeeting();
      },
      connectionStateChanged: (state, reason) {
        if (state == ConnectionStateType.Disconnected) exitMeeting();
      },
      userJoined: (uid, elapsed) async {
        int index = userUIDs.indexOf(uid.toString());
        if (index == -1) {
          userUIDs.add(uid.toString());
          usersMuted.add(false);
          usersVidOff.add(false);

          FirebaseFirestore.instance
              .collection("meetings")
              .doc(code)
              .collection("users")
              .doc(uid.toString())
              .snapshots()
              .listen((event) {
            if (userNames.length == userUIDs.length) {
              userNames.setAll(index, [event.get('name')]);
              userImages.setAll(index, [event.get('image_url')]);
            } else {
              userNames.add(event.get('name'));
              userImages.add(event.get('image_url'));
            }
          });
        }

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
        usersVidOff.removeAt(index);
        usersMuted.removeAt(index);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$uid left this meeting"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      remoteAudioStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid.toString());
        usersMuted.setAll(index, [
          state == AudioRemoteState.Stopped &&
              reason == AudioRemoteStateReason.RemoteMuted
        ]);
        print(state);
        FirebaseFirestore.instance
            .collection("meetings")
            .doc(code)
            .collection("users")
            .doc(uid.toString())
            .set({'audio': state}, SetOptions(merge: false));
      },
      remoteVideoStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid.toString());
        usersVidOff.setAll(index, [
          state == VideoRemoteState.Stopped &&
              reason == VideoRemoteStateReason.RemoteMuted
        ]);
        FirebaseFirestore.instance
            .collection("meetings")
            .doc(code)
            .collection("users")
            .doc(uid.toString())
            .set({'video': state}, SetOptions(merge: false));
      },
    ));

    await engine.enableVideo();
    await engine.enableAudio();

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

  exitMeeting() async {
    await FirebaseFirestore.instance
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(uid)
        .delete();

    userUIDs = [];
    userImages = [FirebaseAuth.instance.currentUser.photoURL];
    userNames = [FirebaseAuth.instance.currentUser.displayName + ' (You)'];
    usersMuted = [];
    usersVidOff = [];
    messages = [];
    messageUsers = [];
    messageTime = [];
  }
}
