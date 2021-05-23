import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gmeet/Services/database.dart';

class MeetingCode extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MeetingCodeState();
  }
}

class MeetingCodeState extends State<MeetingCode> {
  TextEditingController _controller;
  var ifCode = false;

  void join() {
    Database().joinMeeting(_controller.text);
  }

  void present() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Colors.black54,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          splashRadius: 20,
        ),
        title: Text(
          "Enter a meeting code",
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Product Sans',
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 40,
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width - 60,
              height: 50,
              child: TextField(
                autofocus: true,
                textAlignVertical: TextAlignVertical.center,
                controller: _controller,
                autocorrect: false,
                onSubmitted: (val) {
                  join();
                },
                onChanged: (val) {
                  setState(() {
                    if (val.isNotEmpty)
                      ifCode = true;
                    else
                      ifCode = false;
                  });
                },
                cursorColor: Colors.green[800],
                decoration: InputDecoration(
                  labelText: "Meeting code",
                  border: OutlineInputBorder(borderSide: BorderSide()),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MaterialButton(
                animationDuration: Duration(milliseconds: 0),
                elevation: 0,
                textColor: Colors.green[900],
                child: Text(
                  "Present",
                  style: TextStyle(
                    fontFamily: 'Product Sans',
                  ),
                ),
                splashColor: Colors.transparent,
                onPressed: ifCode ? present : null,
                padding: EdgeInsets.only(left: 25, right: 25),
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey[300], width: 1),
                    borderRadius: BorderRadius.circular(3)),
              ),
              SizedBox(
                width: 8,
              ),
              MaterialButton(
                animationDuration: Duration(milliseconds: 0),
                color: Colors.green[900],
                textColor: Colors.white,
                elevation: 0,
                child: Text(
                  "Join meeting",
                  style: TextStyle(
                    fontFamily: 'Product Sans',
                  ),
                ),
                splashColor: Colors.transparent,
                disabledColor: Colors.grey,
                onPressed: ifCode ? join : null,
                padding: EdgeInsets.only(left: 25, right: 25),
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey[300], width: 1),
                    borderRadius: BorderRadius.circular(3)),
              ),
              SizedBox(
                width: 30,
              )
            ],
          ),
        ],
      ),
    );
  }
}
