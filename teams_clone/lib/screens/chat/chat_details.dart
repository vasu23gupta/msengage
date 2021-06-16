import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/home/home.dart';
import 'package:teams_clone/services/chat.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/screens/chat/chat_home.dart';

class ChatDetails extends StatefulWidget {
  final ChatRoom room;
  const ChatDetails(this.room);
  @override
  _ChatDetailsState createState() => _ChatDetailsState();
}

class _ChatDetailsState extends State<ChatDetails> {
  late ChatRoom _room;
  User? _user;
  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    _room = widget.room;
  }

  @override
  void dispose() {
    super.dispose();
    socket.emit("unsubscribe", {"room": _room.roomId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Details",
            style: TextStyle(color: Colors.black, fontSize: 17)),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person_remove_alt_1_outlined),
            title: Text("Leave chat"),
            onTap: () async {
              bool left = await ChatDatabaseService.leaveChatRoom(
                  _room.roomId, _user!.uid);
              if (left) {
                int _count = 0;
                Navigator.popUntil(context, (route) => _count++ == 2);
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => Home()));
              }
            },
          )
        ],
      ),
    );
  }
}
