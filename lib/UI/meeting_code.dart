import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gmeet/Services/database.dart';
import 'package:gmeet/UI/join.dart';

class MeetingCode extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MeetingCodeState();
  }
}

class MeetingCodeState extends State<MeetingCode> {
  TextEditingController _controller = TextEditingController();
  var _ifCodeEntered = false;
  var _validate = true;
  var _loading = false;

  void join() async {
    setState(() {
      _loading = true;
    });
    if (await Database().ifMeetingExists(_controller.text))
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Join(
                    code: _controller.text,
                  )));
    else {
      setState(() {
        _validate = false;
        _ifCodeEntered = false;
      });
    }
    setState(() {
      _loading = false;
    });
  }

  void present() {}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _loading ? 0.5 : 1,
      child: Scaffold(
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
        body: Stack(
          children: [
            _loading
                ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.green[800],
                      ),
                  )
                : SizedBox(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 40,
                ),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width - 60,
                    height: _validate ? 50 : 72,
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
                          _validate = true;
                          if (val.isNotEmpty)
                            _ifCodeEntered = true;
                          else
                            _ifCodeEntered = false;
                        });
                      },
                      cursorColor: Colors.teal[800],
                      decoration: InputDecoration(
                        suffixIcon: _validate
                            ? null
                            : Icon(
                                Icons.error,
                                color: Colors.red[800],
                              ),
                        labelText: "Meeting code",
                        errorText: _validate ? null : "No such meeting",
                        labelStyle: TextStyle(
                            color:
                                _validate ? Colors.teal[800] : Colors.red[800]),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                          color: Colors.teal[800],
                          width: 2,
                        )),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                          color: Colors.teal[800],
                          width: 2,
                        )),
                        focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                          color: Colors.red[800],
                          width: 2,
                        )),
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
                      textColor: Colors.teal[800],
                      child: Text(
                        "Present",
                        style: TextStyle(
                          fontFamily: 'Product Sans',
                        ),
                      ),
                      splashColor: Colors.transparent,
                      onPressed: _ifCodeEntered ? present : null,
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
                      color: Colors.teal[800],
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
                      onPressed: _ifCodeEntered ? join : null,
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
          ],
        ),
      ),
    );
  }
}
