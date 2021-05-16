import 'package:flutter/material.dart';

class MeetingCode extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MeetingCodeState();
  }
}

class MeetingCodeState extends State<MeetingCode> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black54,),
          onPressed: () {
            Navigator.pop(context);
          },
          splashRadius: 20,
        ),
        title: Text("Enter a meeting code", style: TextStyle(
          color: Colors.black,
          fontFamily: 'Product Sans',
          fontSize: 20,
        ),),
      ),
    );
  }
}