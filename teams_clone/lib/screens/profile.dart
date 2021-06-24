import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/AppUser.dart';
import 'package:teams_clone/shared/constants.dart';

class Profile extends StatefulWidget {
  final AppUser appUser;
  const Profile({required this.appUser});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    _appUser = AppUser.fromFirebaseUser(_user!);
  }

  late User? _user;
  late AppUser _appUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: APPBAR_ICON_THEME,
        title: Text(_appUser.name, style: APPBAR_TEXT_STYLE),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(child: _appUser.icon),
        ],
      ),
    );
  }
}
