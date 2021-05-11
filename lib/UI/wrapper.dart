import 'package:flutter/material.dart';
import 'package:gmeet/UI/home.dart';
import 'package:gmeet/UI/welcome.dart';
import 'package:gmeet/models/user.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserIn>(context);

    if(user == null)
      return Welcome();
    else
      return Home();
  }
}