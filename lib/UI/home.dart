import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  var clr1 = Colors.green[800];
  var clr2 = Colors.transparent;
  var clr3 = Colors.transparent;
  var icon = Icons.volume_up_outlined;

  void mic() {}

  void video() {}

  void newMeeting() {}

  void meetingCode() {}

  void menu() {}

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
                  style: TextStyle(
                      color: Colors.black, fontFamily: 'Product Sans'),
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
                  style: TextStyle(
                      color: Colors.black, fontFamily: 'Product Sans'),
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
                  style: TextStyle(
                      color: Colors.black, fontFamily: 'Product Sans'),
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
                  style: TextStyle(
                      color: Colors.black, fontFamily: 'Product Sans'),
                ),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Center(
          child: Text(
            "Meet",
            style: TextStyle(
              fontFamily: 'Product Sans',
            ),
          ),
        ),
        leading: IconButton(
          onPressed: menu,
          splashRadius: 20,
          splashColor: Colors.transparent,
          highlightColor: Colors.white10,
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
        ),
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
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white)),
                  child: IconButton(
                    splashRadius: 25,
                    icon: Icon(Icons.mic_none),
                    onPressed: mic,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 40,
                ),
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white)),
                  child: IconButton(
                    splashRadius: 25,
                    icon: Icon(Icons.videocam_outlined),
                    onPressed: video,
                    color: Colors.white,
                  ),
                )
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Divider(
                    thickness: 2,
                    indent: 195,
                    endIndent: 195,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 5, bottom: 20, left: 10, right: 5),
                          child: ElevatedButton.icon(
                              icon: Icon(
                                Icons.add,
                                color: Colors.green[900],
                              ),
                              label: Text(
                                "New meeting",
                                style: TextStyle(
                                    color: Colors.green[900],
                                    fontFamily: 'Product Sans'),
                              ),
                              onPressed: newMeeting,
                              style: ElevatedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.grey[300], width: 1),
                                elevation: 0,
                                primary: Colors.white,
                                onPrimary: Colors.green[900],
                                shadowColor: Colors.transparent,
                              )),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 5, bottom: 20, left: 5, right: 10),
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.keyboard,
                              color: Colors.green[900],
                            ),
                            label: Text(
                              "Meeting code",
                              style: TextStyle(
                                  color: Colors.green[900],
                                  fontFamily: 'Product Sans'),
                            ),
                            onPressed: meetingCode,
                            style: ElevatedButton.styleFrom(
                              side:
                                  BorderSide(color: Colors.grey[300], width: 1),
                              elevation: 0,
                              primary: Colors.white,
                              onPrimary: Colors.green[900],
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Swipe up to see your meetings",
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontFamily: 'Product Sans',
                          fontSize: 12.5),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
