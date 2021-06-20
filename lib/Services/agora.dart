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
      "0066d4aa2fdccfd43438c4c811d12f16141IACx6zZjTLmfKpVof0lLGBp2JMq3o/PU35YBtA9VQgj2Oc7T9ukAAAAAEABlU0aL4U7PYAEAAQDiTs9g";
  String code = "meet";
  final _user = FirebaseAuth.instance.currentUser;
  FirebaseFirestore _db = FirebaseFirestore.instance;
  RtcEngine engine;
  List<Users> users = [];
  List<int> agoraUIDs = [];
  /*List<String> googleUID = [FirebaseAuth.instance.currentUser.uid];
  List<String> userImages = [FirebaseAuth.instance.currentUser.photoURL];
  List<String> userNames = [
    FirebaseAuth.instance.currentUser.displayName + ' (You)'
  ];
  List<bool> isMuted = [];
  List<bool> isVidOff = [];
  List<double> position = [];*/
  List<String> usersHere = [];
  List<String> messages = [];
  List<String> messageUsers = [];
  List<String> messageTime = [];
  List<String> messageId = [];
  List<bool> msgSentReceived = [];
  Timer _timer;
  int msgCount = 0;
  int currentUserIndex = 0;
  bool askingToJoin = false;
  bool isHost = false;
  bool isAlreadyAccepted = false;
  bool cancelled = false;
  bool meetCreated = false;
  bool isExiting = false;

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

    Future.delayed(Duration(seconds: 10), () {
      if (!meetCreated) {
        homeState.stopLoading();
        engine.leaveChannel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Failed to create meeting. Please check your Internet connection and try again."),
            duration: Duration(milliseconds: 2000),
          ),
        );
      }
    });

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

        agoraUIDs.add(uid);

        users.add(Users(
          googleUID: _user.uid,
          name: _user.displayName + ' (You)',
          image: _user.photoURL,
          isMuted: HomeState.isMuted,
          isVidOff: HomeState.isVidOff,
          position: MediaQuery.of(context).size.width * 2 / 3,
        ));

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Live(
                      agora: this,
                    )));

        if (usersHere.isNotEmpty)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(usersHere.length == 1
                  ? usersHere[0] + " has joined."
                  : usersHere.length == 2
                      ? usersHere[0] + " and " + usersHere[1] + " have joined."
                      : usersHere[0] +
                          ", " +
                          usersHere[1] +
                          " and " +
                          usersHere.length.toString() +
                          " others have joined."),
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
          list.forEach((element) {
            DocumentSnapshot<Map<String, dynamic>> snap = element.doc;
            Map<String, dynamic> map = snap.data();
            if (element.type == DocumentChangeType.removed) {
              if (snap.id != _user.uid) {
                int i = 0;
                for (; i < users.length; i++) {
                  if (users[i].googleUID == snap.id) break;
                }
                users.removeAt(i);
                if (currentUserIndex == i) currentUserIndex--;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(map['name'] + " has left"),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              } else {
                isExiting = true;
              }
            } else if (element.type == DocumentChangeType.added &&
                snap.id != _user.uid) {
              Users newUser = Users(
                googleUID: snap.id,
                name: map['name'],
                image: map['image_url'],
                isMuted: map['isMuted'],
                isVidOff: map['isVidOff'],
                position: MediaQuery.of(context).size.width * 2 / 3,
              );
              users.add(newUser);
              currentUserIndex = users.indexOf(newUser);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(map['name'] + " has joined"),
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else if (snap.id != _user.uid) {
              int index = 0;
              users.forEach((element) {
                if (element.image == map['image_url']) {
                  element.isMuted = map['isMuted'];
                  element.isVidOff = map['isVidOff'];
                  if (!map['isMuted'] || !map['isVidOff'])
                    currentUserIndex = index;
                }
                index++;
              });
            }
          });
          notifyListeners();
        });

        _db
            .collection("meetings")
            .doc(code)
            .collection("messages")
            .snapshots()
            .listen((event) {
          List<DocumentChange<Map<String, dynamic>>> list = event.docChanges;
          list.forEach((element) {
            if (element.type == DocumentChangeType.added &&
                element.doc.id != _user.uid) {
              DocumentSnapshot<Map<String, dynamic>> snap = element.doc;
              if (_timer != null &&
                  _timer.isActive &&
                  messageId[0] == snap.id) {
                messageId.insert(0, snap.id);
                messageUsers.insert(0, "");
                messageTime.insert(0, "");
                messages.insert(0, snap.get('message'));
              } else {
                messageId.insert(0, snap.id);
                messageUsers.insert(0, snap.get('name'));
                messageTime.insert(0, "Now");
                messages.insert(0, snap.get('message'));
              }

              msgCount++;
              msgSentReceived.insert(0, true);
              notifyListeners();

              if (messageTime[0].isNotEmpty) {
                var length = messageTime.length;
                var time = DateFormat('hh:mm a').format(DateTime.now());
                int i = 1;

                _timer = Timer(Duration(seconds: 45), () {});

                Timer.periodic(Duration(minutes: 1), (timer) {
                  if (i == 31) {
                    messageTime.setAll(messageTime.length - length, [time]);
                    timer.cancel();
                  } else {
                    messageTime.setAll(
                        messageTime.length - length, [(i).toString() + " min"]);
                    i++;
                  }
                  notifyListeners();
                });
              }
            }
          });
        });

        _db
            .collection("meetings")
            .doc(code)
            .collection("requests")
            .snapshots()
            .listen((event) {
          List<DocumentChange<Map<String, dynamic>>> list = event.docChanges;
          list.forEach((element) {
            DocumentSnapshot<Map<String, dynamic>> snapshot = element.doc;
            if (snapshot.exists) {
              if (element.type != DocumentChangeType.removed) {
                Map<String, dynamic> map = snapshot.data();
                if (!map['isAccepted'])
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
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
                          contentPadding:
                              EdgeInsets.only(left: 24, right: 24, top: 24),
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
        if (state == ConnectionStateType.Disconnected ||
            state == ConnectionStateType.Failed) exitMeeting();
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
        if (!agoraUIDs.contains(uid)) {
          agoraUIDs.add(uid);
          notifyListeners();
        }
      },
      userOffline: (int uid, UserOfflineReason reason) {
        agoraUIDs.remove(uid);
        notifyListeners();
      },
      remoteAudioStats: (stats) {
        if (stats.uid != agoraUIDs[0])
          currentUserIndex = agoraUIDs.indexOf(stats.uid);
        notifyListeners();
      },
      remoteVideoStats: (stats) {
        if (stats.uid != agoraUIDs[0])
          currentUserIndex = agoraUIDs.indexOf(stats.uid);
        notifyListeners();
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
        .doc(_user.uid)
        .set({
      'name': _user.displayName,
      'image_url': _user.photoURL,
      'isMuted': HomeState.isMuted,
      'isVidOff': HomeState.isVidOff,
    });

    meetCreated = true;
  }

  Future<bool> ifMeetingExists(String code) async {
    DocumentSnapshot document =
        await _db.collection("meetings").doc(code).get();
    if (document.exists) {
      DocumentSnapshot<Map<String, dynamic>> request = await _db
          .collection("meetings")
          .doc(code)
          .collection("requests")
          .doc(_user.uid)
          .get();
      if (document.get('host') == _user.uid ||
          (request.exists && request.get('isAccepted'))) {
        isAlreadyAccepted = true;
        _db
            .collection("meetings")
            .doc(code)
            .collection("users")
            .snapshots()
            .listen((event) {
          List<DocumentChange<Map<String, dynamic>>> list = event.docChanges;
          list.forEach((element) {
            DocumentSnapshot<Map<String, dynamic>> snap = element.doc;
            if (element.type == DocumentChangeType.removed)
              usersHere.remove(snap.get('name'));
            else
              usersHere.add(snap.get('name'));
            notifyListeners();
          });
        });
      }
      return true;
    }
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

        agoraUIDs.insert(0, uid);
        users.add(Users(
          googleUID: _user.uid,
          name: _user.displayName + ' (You)',
          image: _user.photoURL,
          isMuted: HomeState.isMuted,
          isVidOff: HomeState.isVidOff,
          position: MediaQuery.of(context).size.width * 2 / 3,
        ));
        notifyListeners();

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Live(
                      agora: this,
                    )));

        usersHere.remove(_user.displayName);

        if (usersHere.isNotEmpty)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(usersHere.length == 1
                  ? usersHere[0] + " has joined."
                  : usersHere.length == 2
                      ? usersHere[0] + " and " + usersHere[1] + " have joined."
                      : usersHere[0] +
                          ", " +
                          usersHere[1] +
                          " and " +
                          usersHere.length.toString() +
                          " others have joined."),
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
          list.forEach((element) {
            DocumentSnapshot<Map<String, dynamic>> snap = element.doc;
            Map<String, dynamic> map = snap.data();
            if (element.type == DocumentChangeType.removed) {
              if (snap.id != _user.uid) {
                int i = 0;
                for (; i < users.length; i++) {
                  if (users[i].googleUID == snap.id) break;
                }
                users.removeAt(i);
                if (currentUserIndex == i) currentUserIndex--;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(map['name'] + " has left"),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              } else {
                isExiting = true;
              }
            } else if (element.type == DocumentChangeType.added &&
                snap.id != _user.uid) {
              Users newUser = Users(
                googleUID: snap.id,
                name: map['name'],
                image: map['image_url'],
                isMuted: map['isMuted'],
                isVidOff: map['isVidOff'],
                position: MediaQuery.of(context).size.width * 2 / 3,
              );
              users.add(newUser);
              currentUserIndex = users.indexOf(newUser);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(map['name'] + " has joined"),
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else if (snap.id != _user.uid) {
              int index = 0;
              users.forEach((element) {
                if (element.image == map['image_url']) {
                  element.isMuted = map['isMuted'];
                  element.isVidOff = map['isVidOff'];
                  if (!map['isMuted'] || !map['isVidOff'])
                    currentUserIndex = index;
                }
                index++;
              });
            } else {
              HomeState.isMuted = map['isMuted'];
              users[0].isMuted = HomeState.isMuted;
              engine.muteLocalAudioStream(map['isMuted']);
            }
          });
          notifyListeners();
        });

        _db
            .collection("meetings")
            .doc(code)
            .collection("messages")
            .snapshots()
            .listen((event) {
          List<DocumentChange<Map<String, dynamic>>> list = event.docChanges;
          list.forEach((element) {
            if (element.type == DocumentChangeType.added &&
                element.doc.id != _user.uid) {
              DocumentSnapshot<Map<String, dynamic>> snap = element.doc;
              if (_timer != null &&
                  _timer.isActive &&
                  messageId[0] == snap.id) {
                messageId.insert(0, snap.id);
                messageUsers.insert(0, "");
                messageTime.insert(0, "");
                messages.insert(0, snap.get('message'));
              } else {
                messageId.insert(0, snap.id);
                messageUsers.insert(0, snap.get('name'));
                messageTime.insert(0, "Now");
                messages.insert(0, snap.get('message'));
              }

              msgCount++;
              msgSentReceived.insert(0, true);
              notifyListeners();

              if (messageTime[0].isNotEmpty) {
                var length = messageTime.length;
                var time = DateFormat('hh:mm a').format(DateTime.now());
                int i = 1;

                _timer = Timer(Duration(seconds: 45), () {});

                Timer.periodic(Duration(minutes: 1), (timer) {
                  if (i == 31) {
                    messageTime.setAll(messageTime.length - length, [time]);
                    timer.cancel();
                  } else {
                    messageTime.setAll(
                        messageTime.length - length, [(i).toString() + " min"]);
                    i++;
                  }
                  notifyListeners();
                });
              }
            }
          });
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
            list.forEach((element) {
              DocumentSnapshot<Map<String, dynamic>> snapshot = element.doc;
              if (snapshot.exists) {
                if (element.type != DocumentChangeType.removed) {
                  Map<String, dynamic> map = snapshot.data();
                  if (!map['isAccepted'])
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
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
                            contentPadding:
                                EdgeInsets.only(left: 24, right: 24, top: 24),
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
        if (state == ConnectionStateType.Disconnected ||
            state == ConnectionStateType.Failed) exitMeeting();
      },
      userJoined: (uid, elapsed) async {
        if (!agoraUIDs.contains(uid)) {
          agoraUIDs.add(uid);
          notifyListeners();
        }
      },
      userOffline: (int uid, UserOfflineReason reason) {
        agoraUIDs.remove(uid.toString());
        notifyListeners();
      },
      remoteAudioStats: (stats) {
        if (stats.uid != agoraUIDs[0])
          currentUserIndex = agoraUIDs.indexOf(stats.uid);
        notifyListeners();
      },
      remoteVideoStats: (stats) {
        if (stats.uid != agoraUIDs[0])
          currentUserIndex = agoraUIDs.indexOf(stats.uid);
        notifyListeners();
      },
    ));

    await engine.enableVideo();
    await engine.enableAudio();

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
        if (!cancelled)
          Fluttertoast.showToast(
            msg: "Someone in the meeting denied your request to join",
            gravity: ToastGravity.BOTTOM,
            textColor: Colors.white,
            backgroundColor: Colors.grey[800],
          );
        else
          cancelled = false;
        terminate();
      } else if (event.get('isAccepted')) joinExistingChannel(context, code);
    });
  }

  cancelAskToJoin(String code) async {
    cancelled = true;
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
      'isMuted': HomeState.isMuted,
      'isVidOff': HomeState.isVidOff,
    }, SetOptions(merge: false));
  }

  sendMessage(String msg) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("messages")
        .doc(_user.uid)
        .set({
      'name': _user.displayName,
      'message': msg,
    }, SetOptions(merge: false));
  }

  deleteMessage() async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("messages")
        .doc(_user.uid)
        .delete();
  }

  muteAudio(bool muted) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(_user.uid)
        .update({'isMuted': muted});
  }

  muteVideo(bool off) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(_user.uid)
        .update({'isVidOff': off});
  }

  exitMeeting() async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(_user.uid)
        .delete();
    terminate();
  }

  removeUser(int index) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(users[index].googleUID)
        .delete();
  }

  muteUser(int index) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(users[index].googleUID)
        .update({'isMuted': true});
  }

  terminate() {
    _timer?.cancel();
    agoraUIDs.clear();
    users.clear();
    messages.clear();
    messageUsers.clear();
    messageTime.clear();
    msgSentReceived.clear();
    usersHere.clear();
    currentUserIndex = 0;
    msgCount = 0;
    askingToJoin = false;
    isHost = false;
    isAlreadyAccepted = false;
    meetCreated = false;
    _db.terminate();
    _db = FirebaseFirestore.instance;
    HomeState.isVidOff = true;
    notifyListeners();
  }
}

class Users {
  Users(
      {this.googleUID,
      this.name,
      this.image,
      this.position,
      this.isMuted,
      this.isVidOff});
  String googleUID;
  String image;
  String name;
  bool isMuted;
  bool isVidOff;
  double position;
}
