import 'package:flutter/material.dart';
import 'package:teams_clone/models/ChatRoom.dart';

class ChatDetails extends StatefulWidget {
  final ChatRoom chatRoom;
  const ChatDetails(this.chatRoom);
  @override
  _ChatDetailsState createState() => _ChatDetailsState();
}

class _ChatDetailsState extends State<ChatDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Details",
            style: TextStyle(color: Colors.black, fontSize: 17)),
      ),
    );
  }
}
