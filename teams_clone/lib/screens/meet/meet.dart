import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/services/jitsi_meet.dart';
import 'package:teams_clone/shared/constants.dart';

class Meeting extends StatefulWidget {
  @override
  _MeetingState createState() => _MeetingState();
}

class _MeetingState extends State<Meeting> {
  TextEditingController _roomText = TextEditingController();
  late User? _user;

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: meetConfig()));
  }

  Widget meetConfig() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _roomText,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter organiser's Email",
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => MeetingService.joinMeeting(
                MeetingService.emailToJitsiRoomId(_roomText.text), _user!),
            child: Text("Join Meeting"),
            style: ElevatedButton.styleFrom(primary: PURPLE_COLOR),
          ),
          Text("OR"),
          ElevatedButton(
            onPressed: () => MeetingService.joinMeeting(
                MeetingService.emailToJitsiRoomId(_user!.email!), _user!),
            child: Text("Create Meeting"),
            style: ElevatedButton.styleFrom(primary: PURPLE_COLOR),
          ),
        ],
      ),
    );
  }
}
