import 'dart:math';
import 'dart:async';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gmeet/UI/home.dart';
import 'package:gmeet/UI/live.dart';
import 'package:intl/intl.dart';

class Agora extends ChangeNotifier {
  final _appId = "6d4aa2fdccfd43438c4c811d12f16141";
  final _token =
      "0066d4aa2fdccfd43438c4c811d12f16141IAAXCzxMS7hDdmRJ3RgV90jIsNuvzXQzKm3b174hnCdoQs7T9ukAAAAAEAARnS3HdarJYAEAAQB1qslg";
  RtcEngine engine;
  List<int> userUIDs = [];
  List<String> userImages = [FirebaseAuth.instance.currentUser.photoURL];
  List<String> userNames = [
    FirebaseAuth.instance.currentUser.displayName + ' (You)'
  ];
  List<bool> usersMuted = [];
  List<bool> usersVidOff = [];
  List<String> messages = [];
  List<String> messageUsers = [];
  List<String> messageTime = [];
  FirebaseFirestore _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  String code = "meet";
  DocumentSnapshot document;
  Timer _timer;
  int msgCount = 0;
  bool askingToJoin = false;
  bool isHost = false;

  createChannel(BuildContext context, HomeState homeState) async {
    isHost = true;
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

        await createMeetingInDB();

        userUIDs.add(uid);
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

        _db
            .collection("meetings")
            .doc(code)
            .collection("users")
            .snapshots()
            .listen((event) {
          List<DocumentChange<Map<String, dynamic>>> list = event.docChanges;
          List<QueryDocumentSnapshot<Map<String, dynamic>>> doc = event.docs;
          bool present = false;
          list.forEach((element) {
            DocumentSnapshot<Map<String, dynamic>> snap = element.doc;
            Map<String, dynamic> map = snap.data();
            doc.forEach((element) {
              if (element.id == snap.id) present = true;
            });
            if (!present) {
              int index = userImages.indexOf(map['image_url']);
              userNames.remove(map['name']);
              userImages.remove(map['image_url']);
              usersMuted.removeAt(index);
              usersVidOff.removeAt(index);
            } else if (snap.id != _user.uid) {
              userNames.add(map['name']);
              userImages.add(map['image_url']);
            }
          });
          notifyListeners();
        });

        _db
            .collection("meetings")
            .doc(code)
            .collection("requests")
            .snapshots()
            .listen((event) {
          List<DocumentChange<Map<String, dynamic>>> list = event.docChanges;
          List<QueryDocumentSnapshot<Map<String, dynamic>>> doc = event.docs;

          bool present = false;

          list.forEach((element) {
            DocumentSnapshot<Map<String, dynamic>> snapshot = element.doc;
            if (snapshot.exists) {
              doc.forEach((element) {
                if (element.id == snapshot.id) present = true;
              });

              if (present) {
                Map<String, dynamic> map = snapshot.data();
                if (!map['isAccepted'])
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                    height: 40,
                                    width: 40,
                                    child: Image.network(map['image_url'])),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Container(
                                width: 200,
                                child: Text(
                                  "Someone called " +
                                      map['name'] +
                                      " wants to join this meeting",
                                  style: TextStyle(fontSize: 16),
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                            ],
                          ),
                          contentPadding: EdgeInsets.only(
                              left: 24, right: 24, top: 10, bottom: 10),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  _db
                                      .collection("meetings")
                                      .doc(code)
                                      .collection("requests")
                                      .doc(snapshot.id)
                                      .delete();
                                },
                                child: Text(
                                  "Deny entry",
                                  style: TextStyle(
                                      color: Colors.teal[800],
                                      fontSize: 16,
                                      fontFamily: 'Product Sans'),
                                )),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _db
                                      .collection("meetings")
                                      .doc(code)
                                      .collection("requests")
                                      .doc(snapshot.id)
                                      .set({'isAccepted': true});
                                },
                                child: Text(
                                  "Admit",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.teal[800],
                                      fontFamily: 'Product Sans'),
                                )),
                          ],
                        );
                      });
              } else {
                Navigator.pop(context);
              }
            }
          });
        });
      },
      connectionLost: () {
        exitMeeting();
      },
      connectionStateChanged: (state, reason) {
        if (state == ConnectionStateType.Disconnected) exitMeeting();
      },
      error: (errorCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error : $errorCode"),
            duration: Duration(milliseconds: 1000),
          ),
        );
        homeState.stopLoading();
      },
      userJoined: (uid, elapsed) async {
        if (!userUIDs.contains(uid)) {
          userUIDs.add(uid);
          usersVidOff.add(false);
          usersMuted.add(false);
          notifyListeners();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$uid joined this meeting"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      userOffline: (int uid, UserOfflineReason reason) {
        userUIDs.remove(uid);
        notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$uid left this meeting"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      streamMessage: (uid, streamId, data) {
        if (_timer != null &&
            _timer.isActive &&
            messageUsers[0] == userNames.elementAt(userUIDs.indexOf(uid))) {
          messageUsers.setAll(0, [userNames.elementAt(userUIDs.indexOf(uid))]);
          messageTime.setAll(0, ["Now"]);
          messages.setAll(0, [messages[0] + "\n\n" + data]);
        } else {
          messageUsers.insert(0, userNames.elementAt(userUIDs.indexOf(uid)));
          messageTime.insert(0, "Now");
          messages.insert(0, data);
        }

        msgCount++;
        notifyListeners();

        var length = messageTime.length;
        var time = DateFormat('hh:mm a').format(DateTime.now());
        int i = 1;

        _timer = Timer(Duration(seconds: 45), () {});

        Timer.periodic(Duration(minutes: 1), (timer) {
          if (i == 31) {
            messageTime.setAll(messageTime.length - length, [time]);
            timer.cancel();
            notifyListeners();
          } else {
            messageTime
                .setAll(messageTime.length - length, [(i).toString() + " min"]);
            i++;
            notifyListeners();
          }
        });
      },
      remoteAudioStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid);
        usersMuted.setAll(index, [
          state == AudioRemoteState.Stopped &&
              reason == AudioRemoteStateReason.RemoteMuted
        ]);
        notifyListeners();
      },
      remoteVideoStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid);
        usersVidOff.setAll(index, [
          state == VideoRemoteState.Stopped &&
              reason == VideoRemoteStateReason.RemoteMuted
        ]);
        notifyListeners();
      },
    ));

    await engine.enableVideo();
    await engine.enableAudio();

    await engine.muteLocalVideoStream(HomeState.isVidOff);
    await engine.muteLocalAudioStream(HomeState.isMuted);

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
        .doc(_user.uid)
        .set({
      'name': _user.displayName,
      'image_url': _user.photoURL,
    });
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

        await joinMeetingInDB(channel);

        userUIDs.add(uid);
        usersMuted.add(HomeState.isMuted);
        usersVidOff.add(HomeState.isVidOff);
        notifyListeners();

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

        _db
            .collection("meetings")
            .doc(code)
            .collection("users")
            .snapshots()
            .listen((event) {
          List<DocumentChange<Map<String, dynamic>>> list = event.docChanges;
          List<QueryDocumentSnapshot<Map<String, dynamic>>> doc = event.docs;
          bool present = false;
          list.forEach((element) {
            DocumentSnapshot<Map<String, dynamic>> snap = element.doc;
            Map<String, dynamic> map = snap.data();
            doc.forEach((element) {
              if (element.id == snap.id) present = true;
            });
            if (!present) {
              int index = userImages.indexOf(map['image_url']);
              userNames.remove(map['name']);
              userImages.remove(map['image_url']);
              usersMuted.removeAt(index);
              usersVidOff.removeAt(index);
            } else if (snap.id != _user.uid) {
              userNames.add(map['name']);
              userImages.add(map['image_url']);
            }
          });
          notifyListeners();
        });

        DocumentSnapshot<Map<String, dynamic>> snap =
            await _db.collection("meetings").doc(code).get();
        Map<String, dynamic> map = snap.data();

        if (map['host'] == _user.uid)
          _db
              .collection("meetings")
              .doc(code)
              .collection("requests")
              .snapshots()
              .listen((event) {
            List<DocumentChange<Map<String, dynamic>>> list = event.docChanges;
            List<QueryDocumentSnapshot<Map<String, dynamic>>> doc = event.docs;

            bool present = false;

            list.forEach((element) {
              DocumentSnapshot<Map<String, dynamic>> snapshot = element.doc;
              if (snapshot.exists) {
                doc.forEach((element) {
                  if (element.id == snapshot.id) present = true;
                });

                if (present) {
                  Map<String, dynamic> map = snapshot.data();
                  if (!map['isAccepted'])
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                      height: 40,
                                      width: 40,
                                      child: Image.network(map['image_url'])),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Container(
                                  width: 200,
                                  child: Text(
                                    "Someone called " +
                                        map['name'] +
                                        " wants to join this meeting",
                                    style: TextStyle(fontSize: 16),
                                    overflow: TextOverflow.clip,
                                  ),
                                ),
                              ],
                            ),
                            contentPadding: EdgeInsets.only(
                                left: 24, right: 24, top: 10, bottom: 10),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    _db
                                        .collection("meetings")
                                        .doc(code)
                                        .collection("requests")
                                        .doc(snapshot.id)
                                        .delete();
                                  },
                                  child: Text(
                                    "Deny entry",
                                    style: TextStyle(
                                        color: Colors.teal[800],
                                        fontSize: 16,
                                        fontFamily: 'Product Sans'),
                                  )),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _db
                                        .collection("meetings")
                                        .doc(code)
                                        .collection("requests")
                                        .doc(snapshot.id)
                                        .set({'isAccepted': true});
                                  },
                                  child: Text(
                                    "Admit",
                                    style: TextStyle(
                                        color: Colors.teal[800],
                                        fontSize: 16,
                                        fontFamily: 'Product Sans'),
                                  )),
                            ],
                          );
                        });
                } else {
                  Navigator.pop(context);
                }
              }
            });
          });
      },
      error: (errorCode) {
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
        if (!userUIDs.contains(uid)) {
          userUIDs.add(uid);
          usersVidOff.add(false);
          usersMuted.add(false);
          notifyListeners();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$uid joined this meeting"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      userOffline: (int uid, UserOfflineReason reason) {
        userUIDs.remove(uid.toString());
        notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$uid left this meeting"),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      streamMessage: (uid, streamId, data) {
        if (_timer != null &&
            _timer.isActive &&
            messageUsers[0] == userNames.elementAt(userUIDs.indexOf(uid))) {
          messageUsers.setAll(0, [userNames.elementAt(userUIDs.indexOf(uid))]);
          messageTime.setAll(0, ["Now"]);
          messages.setAll(0, [messages[0] + "\n\n" + data]);
        } else {
          messageUsers.insert(0, userNames.elementAt(userUIDs.indexOf(uid)));
          messageTime.insert(0, "Now");
          messages.insert(0, data);
        }

        msgCount++;
        notifyListeners();

        var length = messageTime.length;
        var time = DateFormat('hh:mm a').format(DateTime.now());
        int i = 1;

        _timer = Timer(Duration(seconds: 45), () {});

        Timer.periodic(Duration(minutes: 1), (timer) {
          if (i == 31) {
            messageTime.setAll(messageTime.length - length, [time]);
            timer.cancel();
          } else {
            messageTime
                .setAll(messageTime.length - length, [(i).toString() + " min"]);
            i++;
          }
          notifyListeners();
        });
      },
      remoteAudioStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid);
        usersMuted.setAll(index, [
          state == AudioRemoteState.Stopped &&
              reason == AudioRemoteStateReason.RemoteMuted
        ]);
        notifyListeners();
      },
      remoteVideoStateChanged: (uid, state, reason, elapsed) {
        int index = userUIDs.indexOf(uid);
        usersVidOff.setAll(index, [
          state == VideoRemoteState.Stopped &&
              reason == VideoRemoteStateReason.RemoteMuted
        ]);
        notifyListeners();
      },
    ));

    await engine.enableVideo();
    await engine.enableAudio();

    await engine.muteLocalVideoStream(HomeState.isVidOff);
    await engine.muteLocalAudioStream(HomeState.isMuted);

    await engine.joinChannel(_token, channel, null, 0);
  }

  askToJoin(BuildContext context, String code) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection('requests')
        .doc(_user.uid)
        .set({
      'isAccepted': false,
      'name': _user.displayName,
      'image_url': _user.photoURL
    });

    _db
        .collection("meetings")
        .doc(code)
        .collection('requests')
        .doc(_user.uid)
        .snapshots()
        .listen((event) {
      if (!event.exists) {
        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: "Someone in the meeting denied your request to join",
          gravity: ToastGravity.BOTTOM,
          textColor: Colors.white,
          backgroundColor: Colors.black,
        );
      } else if (event.get('isAccepted')) joinExistingChannel(context, code);
    });
  }

  cancelAskToJoin(String code) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection('requests')
        .doc(_user.uid)
        .delete();
  }

  joinMeetingInDB(String code) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(_user.uid)
        .set({
      'name': _user.displayName,
      'image_url': _user.photoURL,
    }, SetOptions(merge: false));
  }

  sendMessage(String msg, String code) async {
    int streamId = await engine.createDataStream(true, true);
    engine.sendStreamMessage(streamId, msg);
  }

  exitMeeting() async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(_user.uid)
        .delete();

    _timer?.cancel();
    userUIDs = [];
    userImages = [FirebaseAuth.instance.currentUser.photoURL];
    userNames = [FirebaseAuth.instance.currentUser.displayName + ' (You)'];
    usersMuted = [];
    usersVidOff = [];
    messages = [];
    messageUsers = [];
    messageTime = [];
    _db = FirebaseFirestore.instance;
  }
}
