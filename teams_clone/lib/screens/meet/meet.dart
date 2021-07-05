import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/services/jitsi_meet.dart';
import 'package:teams_clone/shared/constants.dart';

class Meeting extends StatefulWidget {
  @override
  _MeetingState createState() => _MeetingState();
}

class _MeetingState extends State<Meeting> {
  TextEditingController _joinMeetController = TextEditingController();
  TextEditingController _createMeetController = TextEditingController();
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
              controller: _joinMeetController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter room id",
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _joinMeeting,
            child: Text("Join Meeting"),
            style: ElevatedButton.styleFrom(primary: PURPLE_COLOR),
          ),
          Text("OR"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _createMeetController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter meeting name",
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _createMeeting,
            child: Text("Create Meeting"),
            style: ElevatedButton.styleFrom(primary: PURPLE_COLOR),
          ),
        ],
      ),
    );
  }

  Future<void> _createMeeting() async {
    ChatRoom cr = ChatRoom(roomId: '');
    cr.name = _createMeetController.text;
    String? chatRoomId = await ChatDatabaseService.createNewChatRoom(
        [], cr, _user!.uid, "meeting");
    MeetingService.joinMeeting(chatRoomId, _user!, name: cr.name);
  }

  Future<void> _joinMeeting() async {
    bool done = await ChatDatabaseService.joinChatRoom(
        _joinMeetController.text, _user!);
    if (done)
      MeetingService.joinMeeting(
          MeetingService.emailToJitsiRoomId(_joinMeetController.text), _user!);
    else
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Room not found, please check the room id")));
  }
}
