import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/screens/authenticate/authenticate.dart';
import 'package:teams_clone/screens/home.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _user = Provider.of<User?>(context);

    if (_user == null) {
      return Authenticate();
    } else {
      return Home();
    }
  }
}
