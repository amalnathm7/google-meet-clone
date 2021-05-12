import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  void mic() {}

  void video() {}

  void newMeeting() {}

  void meetingCode() {}

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
        leading: Icon(Icons.menu),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: DropdownButton(
              icon: Icon(Icons.volume_up_outlined),
              underline: SizedBox(),
            ),
          ),
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
                          padding: const EdgeInsets.only(top: 5, bottom: 30, left: 10, right: 5),
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
                                side: BorderSide(color: Colors.grey[300], width: 1),
                                elevation: 0,
                                primary: Colors.white,
                                onPrimary: Colors.green[900],
                                shadowColor: Colors.transparent,
                              )),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 30, left: 5, right: 10),
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
                              side: BorderSide(color: Colors.grey[300], width: 1),
                              elevation: 0,
                              primary: Colors.white,
                              onPrimary: Colors.green[900],
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
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
