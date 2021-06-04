import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login.dart';

class Welcome extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return WelcomeState();
  }
}

class WelcomeState extends State<Welcome> {
  void _launchURL1() async {
    const _url = 'https://policies.google.com/terms';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void _launchURL2() async {
    const _url = 'https://policies.google.com/privacy';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void checkCamAndMic() async {
    if(await Permission.camera.isGranted && await Permission.microphone.isGranted)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
  }

  @override
  void initState() {
    super.initState();
    checkCamAndMic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/welcome.png",
              height: 200,
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              "Welcome to Meet",
              style: TextStyle(fontSize: 20, fontFamily: 'Product Sans'),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 10, left: 50, right: 50, bottom: 8),
              child: Text(
                "To make video calls on Meet, allow access to your device's video camera and microphone",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Product Sans', color: Colors.black54),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _launchURL1,
                  style: ButtonStyle(
                      overlayColor:
                          MaterialStateProperty.all(Colors.transparent),
                      padding: MaterialStateProperty.all(EdgeInsets.zero)),
                  child: Text(
                    "Terms of Service",
                    style: TextStyle(
                        color: Colors.teal[800], fontFamily: 'Product Sans'),
                  ),
                ),
                Text(" and "),
                TextButton(
                  onPressed: _launchURL2,
                  style: ButtonStyle(
                      overlayColor:
                          MaterialStateProperty.all(Colors.transparent),
                      padding: MaterialStateProperty.all(EdgeInsets.zero)),
                  child: Text(
                    "Privacy Policy",
                    style: TextStyle(
                        color: Colors.teal[800], fontFamily: 'Product Sans'),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () async {
                  if (await Permission.camera.isPermanentlyDenied)
                    openAppSettings();
                  if (await Permission.microphone.isPermanentlyDenied)
                    openAppSettings();
                  while (await Permission.camera.request().isDenied) {}
                  while (await Permission.microphone.request().isDenied) {}

                  if(await Permission.camera.isGranted && await Permission.microphone.isGranted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  }
                },
                style: ButtonStyle(
                    overlayColor:
                        MaterialStateProperty.all(Colors.teal[800]),
                    elevation: MaterialStateProperty.all(0),
                    minimumSize: MaterialStateProperty.all(Size.zero),
                    padding: MaterialStateProperty.all(EdgeInsets.only(
                        left: 21, right: 21, top: 8, bottom: 8)),
                    backgroundColor:
                        MaterialStateProperty.all(Colors.teal[800])),
                child: Text(
                  "Continue",
                  style: TextStyle(
                    fontFamily: 'Product Sans',
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ))
          ],
        ),
      ),
    );
  }
}