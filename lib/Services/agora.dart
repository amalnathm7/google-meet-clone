import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:agora_rtc_engine/rtc_remote_view.dart';
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
  final _appCertificate = "f4b51772421c4f4d86b6a497b59cd99d";
  final user = FirebaseAuth.instance.currentUser;
  FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription _usersHereListener;
  String _token;
  String code;
  BuildContext context;
  RtcEngine engine;
  List<Users> users = [];
  List<String> usersHere = [];
  List<String> newUsers = [];
  List<String> messages = [];
  List<String> messageUsers = [];
  List<String> messageTime = [];
  List<String> messageId = [];
  List<bool> msgSentReceived = [];
  Timer _timer, _delay;
  int msgCount = 0;
  int currentUserIndex = 0;
  bool askingToJoin = false;
  bool isHost = false;
  bool isAlreadyAccepted = false;
  bool cancelled = false;
  bool isExiting = false;
  bool meetCreated = false;

  createChannel(HomeState homeState) async {
    isHost = true;
    meetCreated = true;

    const _chars = 'abcdefghijklmnopqrstuvwxyz';
    Random _rnd = Random.secure();
    code = String.fromCharCodes(Iterable.generate(
        10, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
    code = code.substring(0, 3) +
        '-' +
        code.substring(3, 7) +
        '-' +
        code.substring(7, 10);

    final response = await http.post(
        Uri.parse("https://agora-app-server.herokuapp.com/getToken/"),
        body: {
          "uid": "0",
          "appID": _appId,
          "appCertificate": _appCertificate,
          "channelName": code,
        });

    if (response.statusCode == 200) {
      _token = response.body;
      _token = jsonDecode(_token)['token'];
    } else {
      homeState.stopLoading();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create meeting. Please try again."),
          duration: Duration(milliseconds: 2000),
        ),
      );
      return;
    }

    _delay = Timer(Duration(seconds: 10), () {
      homeState.stopLoading();
      engine.leaveChannel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Failed to create meeting. Please check your Internet connection and try again."),
          duration: Duration(milliseconds: 2000),
        ),
      );
    });

    await joinCreatedChannel(code, homeState);
  }

  joinCreatedChannel(String channel, HomeState homeState) async {
    RtcEngineConfig config = RtcEngineConfig(_appId);
    engine = await RtcEngine.createWithConfig(config);

    engine.setEventHandler(RtcEngineEventHandler(
        joinChannelSuccess: (channel, uid, elapsed) async {
      _delay.cancel();

      await engine.muteLocalAudioStream(HomeState.isMuted);
      await engine.muteLocalVideoStream(HomeState.isVidOff);

      await createMeetingInDB(uid);

      users.add(Users(
        googleUID: user.uid,
        agoraUID: uid,
        name: user.displayName + ' (You)',
        image: user.photoURL,
        isMuted: HomeState.isMuted,
        isVidOff: HomeState.isVidOff,
        position: MediaQuery.of(context).size.width * 2 / 3,
        joinedNow: false,
        view: SurfaceView(
          uid: uid,
        ),
      ));

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Live(
                    agora: this,
                  )));

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
            if (snap.id != user.uid) {
              int i = 0;
              for (; i < users.length; i++) {
                if (users[i].googleUID == snap.id) break;
              }
              users.removeAt(i);

              if (users.length > 4) {
                List<Users> list = users.sublist(4);
                list.sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                users.replaceRange(
                    4, users.length, list.getRange(0, list.length));
              }

              if (currentUserIndex == i)
                currentUserIndex = users.length == 1 ? 0 : 1;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(map['name'] + " has left"),
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else {
              isExiting = true;
              notifyListeners();
            }
          } else if (element.type == DocumentChangeType.added &&
              snap.id != user.uid) {
            Users newUser = Users(
                googleUID: snap.id,
                agoraUID: map['uid'],
                name: map['name'],
                image: map['image_url'],
                isMuted: map['isMuted'],
                isVidOff: map['isVidOff'],
                position: MediaQuery.of(context).size.width * 2 / 3,
                joinedNow: true,
                view: SurfaceView(
                  uid: map['uid'],
                ));
            users.add(newUser);

            if (users.length == 2) currentUserIndex = 1;

            if (!newUsers.contains(newUser.name) &&
                !usersHere.contains(newUser.name)) {
              newUsers.add(newUser.name);
              Timer(Duration(seconds: 30), () {
                newUser?.joinedNow = false;
                notifyListeners();
              });
            } else {
              newUser.joinedNow = false;
            }

            if (users.length > 4) {
              List<Users> list = users.sublist(4);
              list.sort((a, b) =>
                  a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              users.replaceRange(
                  4, users.length, list.getRange(0, list.length));
            }

            for (Users value in users) {
              if (value.googleUID == user.uid) {
                users.remove(value);
                users.insert(0, value);
                break;
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(map['name'] + " has joined"),
                duration: Duration(milliseconds: 1000),
              ),
            );
          } else if (snap.id != user.uid) {
            users.forEach((element) {
              if (element.googleUID == snap.id) {
                element.isMuted = map['isMuted'];
                element.isVidOff = map['isVidOff'];
                element.agoraUID = map['uid'];
                element.view = SurfaceView(uid: map['uid']);
                if (!map['isMuted'] || !map['isVidOff']) {
                  int index = 0;
                  for (Users value in users) {
                    if (value.googleUID == snap.id) {
                      users.remove(value);
                      users.insert(index < 4 ? index : 1, value);
                      currentUserIndex = index < 4 ? index : 1;
                      break;
                    }
                    index++;
                  }
                  if (users.length > 4) {
                    List<Users> list = users.sublist(4);
                    list.sort((a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                    users.replaceRange(
                        4, users.length, list.getRange(0, list.length));
                  }
                }
              }
            });
          }
          notifyListeners();
        });
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
              element.doc.id != user.uid) {
            DocumentSnapshot<Map<String, dynamic>> snap = element.doc;
            if (_timer != null && _timer.isActive && messageId[0] == snap.id) {
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
                if (messageTime.isEmpty)
                  timer.cancel();
                else {
                  if (i == 31) {
                    messageTime.setAll(messageTime.length - length, [time]);
                    timer.cancel();
                  } else {
                    messageTime.setAll(
                        messageTime.length - length, [(i).toString() + " min"]);
                    i++;
                  }
                  notifyListeners();
                }
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
    }, error: (errorCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error : $errorCode"),
          duration: Duration(milliseconds: 1000),
        ),
      );
      homeState.stopLoading();
    }, tokenPrivilegeWillExpire: (token) async {
      final response = await http.post(
          Uri.parse("https://agora-app-server.herokuapp.com/getToken/"),
          body: {
            "uid": "0",
            "appID": _appId,
            "appCertificate": _appCertificate,
            "channelName": code,
          });

      if (response.statusCode == 200) {
        _token = response.body;
        _token = jsonDecode(_token)['token'];
        await _db.collection("meetings").doc(code).update({'token': _token});
        engine.renewToken(_token);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("This meeting may end soon."),
            duration: Duration(milliseconds: 2000),
          ),
        );
      }
    }, remoteAudioStateChanged: (uid, state, reason, elapsed) {
      for (Users element in users) {
        if (element.agoraUID == uid) {
          if (state == AudioRemoteState.Stopped &&
              reason == AudioRemoteStateReason.RemoteMuted) {
            element.isMuted = true;
            notifyListeners();
          }
          break;
        }
      }
    }, remoteVideoStateChanged: (uid, state, reason, elapsed) {
      for (Users element in users) {
        if (element.agoraUID == uid) {
          if (state == VideoRemoteState.Stopped &&
              reason == VideoRemoteStateReason.RemoteMuted) {
            element.isVidOff = true;
            notifyListeners();
          }
          break;
        }
      }
    }, remoteAudioStats: (stats) {
      int index = 0;
      for (Users element in users) {
        if (element.agoraUID == stats.uid) break;
        index++;
      }
      if (index >= 4) {
        users.insert(1, users.removeAt(index));
        currentUserIndex = 1;
        if (users.length > 4) {
          List<Users> list = users.sublist(4);
          list.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          users.replaceRange(4, users.length, list.getRange(0, list.length));
          notifyListeners();
        }
      }
    }, remoteVideoStats: (stats) {
      int index = 0;
      for (Users element in users) {
        if (element.agoraUID == stats.uid) break;
        index++;
      }
      if (index >= 4) {
        users.insert(1, users.removeAt(index));
        currentUserIndex = 1;
        if (users.length > 4) {
          List<Users> list = users.sublist(4);
          list.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          users.replaceRange(4, users.length, list.getRange(0, list.length));
        }
        notifyListeners();
      }
    }, audioVolumeIndication: (speakers, totalVolume) {
      speakers.forEach((element) {
        for (Users user in users) {
          if (user.agoraUID == element.uid) {
            if (element.volume < 50) {
              user.volume1 = 5;
              user.volume2 = 5;
            } else if (element.volume < 75) {
              user.volume1 = element.volume / 10;
              user.volume2 = 5;
            } else if (element.volume > 180) {
              user.volume1 = 18;
              user.volume2 = 18;
            } else if (element.volume > 120) {
              user.volume1 = 18;
              user.volume2 = element.volume / 15;
            } else {
              user.volume1 = element.volume / 10;
              user.volume2 = element.volume / 15;
            }
            notifyListeners();
            break;
          }
        }
      });
      if (speakers.isNotEmpty) {
        if (speakers[0].volume < 50) {
          users[0].volume1 = 5;
          users[0].volume2 = 5;
        } else if (speakers[0].volume < 75) {
          users[0].volume1 = speakers[0].volume / 10;
          users[0].volume2 = 5;
        } else if (speakers[0].volume > 180) {
          users[0].volume1 = 18;
          users[0].volume2 = 18;
        } else if (speakers[0].volume > 120) {
          users[0].volume1 = 18;
          users[0].volume2 = speakers[0].volume / 15;
        } else {
          users[0].volume1 = speakers[0].volume / 10;
          users[0].volume2 = speakers[0].volume / 15;
        }
        notifyListeners();
      }
    }));

    await engine.enableVideo();
    await engine.enableAudio();
    await engine.enableAudioVolumeIndication(200, 3, true);

    await engine.joinChannel(_token, channel, null, 0);
  }

  createMeetingInDB(int uid) async {
    await _db
        .collection("meetings")
        .doc(code)
        .set({'host': user.uid, 'token': _token});

    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(user.uid)
        .set({
      'name': user.displayName,
      'image_url': user.photoURL,
      'uid': uid,
      'isMuted': HomeState.isMuted,
      'isVidOff': HomeState.isVidOff,
    });
  }

  Future<bool> ifMeetingExists(String code) async {
    DocumentSnapshot document =
        await _db.collection("meetings").doc(code).get();

    if (document.exists) {
      _token = await document.get('token');

      DocumentSnapshot<Map<String, dynamic>> request = await _db
          .collection("meetings")
          .doc(code)
          .collection("requests")
          .doc(user.uid)
          .get();

      if (document.get('host') == user.uid) isHost = true;
      if (request.exists && request.get('isAccepted')) isAlreadyAccepted = true;

      if (isHost || isAlreadyAccepted) {
        _usersHereListener = _db
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
            else if (element.type == DocumentChangeType.added)
              usersHere.add(snap.get('name'));
            notifyListeners();
          });
        });
      }
      return true;
    }
    return false;
  }

  joinExistingChannel(String channel) async {
    RtcEngineConfig config = RtcEngineConfig(_appId);
    engine = await RtcEngine.createWithConfig(config);

    engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) async {
        await engine.muteLocalAudioStream(HomeState.isMuted);
        await engine.muteLocalVideoStream(HomeState.isVidOff);

        this.code = channel;

        await joinMeetingInDB(channel, uid);

        users.add(Users(
          googleUID: user.uid,
          agoraUID: uid,
          name: user.displayName + ' (You)',
          image: user.photoURL,
          isMuted: HomeState.isMuted,
          isVidOff: HomeState.isVidOff,
          position: MediaQuery.of(context).size.width * 2 / 3,
          joinedNow: false,
          view: SurfaceView(
            uid: uid,
          ),
        ));

        if (askingToJoin) {
          QuerySnapshot<Map<String, dynamic>> snapshot = await _db
              .collection("meetings")
              .doc(code)
              .collection("users")
              .get();
          List<QueryDocumentSnapshot<Map<String, dynamic>>> list =
              snapshot.docs;
          list.forEach((element) {
            usersHere.add(element.get('name'));
          });
        }

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Live(
                      agora: this,
                    )));

        if (usersHere.length > 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(usersHere.length == 2
                  ? usersHere[0] + " has joined."
                  : usersHere.length == 3
                      ? usersHere[0] + " and " + usersHere[1] + " have joined."
                      : usersHere[0] +
                          ", " +
                          usersHere[1] +
                          " and " +
                          (usersHere.length - 3).toString() +
                          " others have joined."),
              duration: Duration(milliseconds: 1000),
            ),
          );
        }

        if (!isHost) {
          _db.collection("meetings").doc(code).snapshots().listen((event) {
            if (event.get('token') != _token) {
              _token = event.get('token');
              engine.renewToken(_token);
            }
          });
        }

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
              if (snap.id != user.uid) {
                int i = 0;
                for (; i < users.length; i++) {
                  if (users[i].googleUID == snap.id) break;
                }
                users.removeAt(i);

                if (currentUserIndex == i)
                  currentUserIndex = users.length == 1 ? 0 : 1;

                if (users.length > 4) {
                  List<Users> list = users.sublist(4);
                  list.sort((a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                  users.replaceRange(
                      4, users.length, list.getRange(0, list.length));
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(map['name'] + " has left"),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              } else {
                isExiting = true;
                notifyListeners();
              }
            } else if (element.type == DocumentChangeType.added &&
                snap.id != user.uid) {
              Users newUser = Users(
                  googleUID: snap.id,
                  agoraUID: map['uid'],
                  name: map['name'],
                  image: map['image_url'],
                  isMuted: map['isMuted'],
                  isVidOff: map['isVidOff'],
                  position: MediaQuery.of(context).size.width * 2 / 3,
                  joinedNow: true,
                  view: SurfaceView(
                    uid: map['uid'],
                  ));
              users.add(newUser);

              if (users.length == 2) currentUserIndex = 1;

              if (users.length > 4) {
                List<Users> list = users.sublist(4);
                list.sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                users.replaceRange(
                    4, users.length, list.getRange(0, list.length));
              }

              for (Users value in users) {
                if (value.googleUID == user.uid) {
                  users.remove(value);
                  users.insert(0, value);
                  break;
                }
              }

              if (!newUsers.contains(newUser.name) &&
                  !usersHere.contains(newUser.name)) {
                newUsers.add(newUser.name);
                Timer(Duration(seconds: 30), () {
                  newUser?.joinedNow = false;
                  notifyListeners();
                });
              } else {
                newUser.joinedNow = false;
              }

              if (!usersHere.contains(newUser.name)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(map['name'] + " has joined"),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              }
            } else if (snap.id != user.uid) {
              users.forEach((element) {
                if (element.googleUID == snap.id) {
                  element.isMuted = map['isMuted'];
                  element.isVidOff = map['isVidOff'];
                  element.agoraUID = map['uid'];
                  element.view = SurfaceView(uid: map['uid']);
                  if (!map['isMuted'] || !map['isVidOff']) {
                    int index = 0;
                    for (Users value in users) {
                      if (value.googleUID == snap.id) {
                        users.remove(value);
                        users.insert(index < 4 ? index : 1, value);
                        currentUserIndex = index < 4 ? index : 1;
                        break;
                      }
                      index++;
                    }
                    if (users.length > 4) {
                      List<Users> list = users.sublist(4);
                      list.sort((a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                      users.replaceRange(
                          4, users.length, list.getRange(0, list.length));
                    }
                  }
                }
              });
            } else {
              HomeState.isMuted = map['isMuted'];
              users[0].isMuted = HomeState.isMuted;
              engine.muteLocalAudioStream(map['isMuted']);
            }
            notifyListeners();
          });
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
                element.doc.id != user.uid) {
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
                  if (messageTime.isEmpty)
                    timer.cancel();
                  else {
                    if (i == 31) {
                      messageTime.setAll(messageTime.length - length, [time]);
                      timer.cancel();
                    } else {
                      messageTime.setAll(messageTime.length - length,
                          [(i).toString() + " min"]);
                      i++;
                    }
                    notifyListeners();
                  }
                });
              }
            }
          });
        });

        if (isHost) {
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
        }
        _usersHereListener?.cancel();
      },
      error: (errorCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error : $errorCode"),
            duration: Duration(milliseconds: 1000),
          ),
        );
        notifyListeners();
      },
      tokenPrivilegeWillExpire: (token) async {
        if (isHost) {
          final response = await http.post(
              Uri.parse("https://agora-app-server.herokuapp.com/getToken/"),
              body: {
                "uid": "0",
                "appID": _appId,
                "appCertificate": _appCertificate,
                "channelName": code,
              });

          if (response.statusCode == 200) {
            _token = response.body;
            _token = jsonDecode(_token)['token'];
            await _db
                .collection("meetings")
                .doc(code)
                .update({'token': _token});
            engine.renewToken(_token);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("This meeting may end soon."),
                duration: Duration(milliseconds: 2000),
              ),
            );
          }
        } else
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Meeting code will expire soon. "
                  "If the host is absent, the meeting may end."),
              duration: Duration(milliseconds: 2000),
            ),
          );
      },
      remoteAudioStateChanged: (uid, state, reason, elapsed) {
        for (Users element in users) {
          if (element.agoraUID == uid) {
            if (state == AudioRemoteState.Stopped &&
                reason == AudioRemoteStateReason.RemoteMuted) {
              element.isMuted = true;
              notifyListeners();
            }
            break;
          }
        }
      },
      remoteVideoStateChanged: (uid, state, reason, elapsed) {
        for (Users element in users) {
          if (element.agoraUID == uid) {
            if (state == VideoRemoteState.Stopped &&
                reason == VideoRemoteStateReason.RemoteMuted) {
              element.isVidOff = true;
              notifyListeners();
            }
            break;
          }
        }
      },
      remoteAudioStats: (stats) {
        int index = 0;
        for (Users element in users) {
          if (element.agoraUID == stats.uid) break;
          index++;
        }
        if (index >= 4) {
          users.insert(1, users.removeAt(index));
          currentUserIndex = 1;
          if (users.length > 4) {
            List<Users> list = users.sublist(4);
            list.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            users.replaceRange(4, users.length, list.getRange(0, list.length));
          }
          notifyListeners();
        }
      },
      remoteVideoStats: (stats) {
        int index = 0;
        for (Users element in users) {
          if (element.agoraUID == stats.uid) break;
          index++;
        }
        if (index >= 4) {
          users.insert(1, users.removeAt(index));
          currentUserIndex = 1;
          if (users.length > 4) {
            List<Users> list = users.sublist(4);
            list.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            users.replaceRange(4, users.length, list.getRange(0, list.length));
          }
          notifyListeners();
        }
      },
      audioVolumeIndication: (speakers, totalVolume) {
        speakers.forEach((element) {
          for (Users user in users) {
            if (user.agoraUID == element.uid) {
              if (element.volume < 50) {
                user.volume1 = 5;
                user.volume2 = 5;
              } else if (element.volume < 75) {
                user.volume1 = element.volume / 10;
                user.volume2 = 5;
              } else if (element.volume > 180) {
                user.volume1 = 18;
                user.volume2 = 18;
              } else if (element.volume > 120) {
                user.volume1 = 18;
                user.volume2 = element.volume / 15;
              } else {
                user.volume1 = element.volume / 10;
                user.volume2 = element.volume / 15;
              }
              notifyListeners();
              break;
            }
          }
          if (speakers.isNotEmpty) {
            if (speakers[0].volume < 50) {
              users[0].volume1 = 5;
              users[0].volume2 = 5;
            } else if (speakers[0].volume < 75) {
              users[0].volume1 = speakers[0].volume / 10;
              users[0].volume2 = 5;
            } else if (speakers[0].volume > 180) {
              users[0].volume1 = 18;
              users[0].volume2 = 18;
            } else if (speakers[0].volume > 120) {
              users[0].volume1 = 18;
              users[0].volume2 = speakers[0].volume / 15;
            } else {
              users[0].volume1 = speakers[0].volume / 10;
              users[0].volume2 = speakers[0].volume / 15;
            }
            notifyListeners();
          }
        });
      },
    ));

    await engine.enableVideo();
    await engine.enableAudio();
    await engine.enableAudioVolumeIndication(200, 3, true);

    await engine.joinChannel(_token, channel, null, 0);
  }

  askToJoin(String code) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection('requests')
        .doc(user.uid)
        .set({
      'isAccepted': false,
      'name': user.displayName,
      'image_url': user.photoURL
    });

    _db
        .collection("meetings")
        .doc(code)
        .collection('requests')
        .doc(user.uid)
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
      } else if (event.get('isAccepted')) joinExistingChannel(code);
    });
  }

  cancelAskToJoin(String code) async {
    cancelled = true;
    await _db
        .collection("meetings")
        .doc(code)
        .collection('requests')
        .doc(user.uid)
        .delete();
  }

  joinMeetingInDB(String code, int uid) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(user.uid)
        .set({
      'name': user.displayName,
      'image_url': user.photoURL,
      'uid': uid,
      'isMuted': HomeState.isMuted,
      'isVidOff': HomeState.isVidOff,
    }, SetOptions(merge: false));
  }

  sendMessage(String msg) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("messages")
        .doc(user.uid)
        .set({
      'name': user.displayName,
      'message': msg,
    }, SetOptions(merge: false));
  }

  deleteMessage() async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("messages")
        .doc(user.uid)
        .delete();
  }

  muteAudio(bool muted) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(user.uid)
        .update({'isMuted': muted});
  }

  muteVideo(bool off) async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(user.uid)
        .update({'isVidOff': off});
  }

  exitMeeting() async {
    await _db
        .collection("meetings")
        .doc(code)
        .collection("users")
        .doc(user.uid)
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
    engine.leaveChannel();
    engine.destroy();
  }
}

class Users {
  Users(
      {this.googleUID,
      this.agoraUID,
      this.name,
      this.image,
      this.position,
      this.isMuted,
      this.isVidOff,
      this.view,
      this.joinedNow,
      this.volume1 = 5,
      this.volume2 = 5});
  String googleUID;
  int agoraUID;
  String image;
  String name;
  bool isMuted;
  bool isVidOff;
  bool joinedNow;
  double position;
  double volume1;
  double volume2;
  SurfaceView view;
}
