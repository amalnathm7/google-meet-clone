import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Welcome extends StatelessWidget {
  void _launchURL1() async {
    const _url = 'https://policies.google.com/terms';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void _launchURL2() async {
    const _url = 'https://policies.google.com/privacy';
    await canLaunch(_url) ? await launch(_url) : throw "Could not launch $_url";
  }

  void nextPage() {}

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
                        color: Colors.green[800], fontFamily: 'Product Sans'),
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
                        color: Colors.green[800], fontFamily: 'Product Sans'),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: nextPage,
                style: ButtonStyle(
                  overlayColor: MaterialStateProperty.all(Colors.green[800]),
                  elevation: MaterialStateProperty.all(0),
                  minimumSize: MaterialStateProperty.all(Size.zero),
                  padding: MaterialStateProperty.all(EdgeInsets.only(left: 21, right: 21, top: 8, bottom: 8)),
                  backgroundColor: MaterialStateProperty.all(Colors.green[900])
                ),
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
