import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/chat/chat.dart';
import 'package:teams_clone/screens/chat/create_chat.dart';
import 'package:teams_clone/services/chat.dart';
import 'package:teams_clone/services/database.dart';

class ChatHome extends StatefulWidget {
  const ChatHome({Key? key}) : super(key: key);

  @override
  _ChatHomeState createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  List<String> _roomIds = [];

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    connectAndListen(_user!.uid);
  }

  User? _user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScaffold(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => CreateChat())),
        child: Icon(Icons.create),
      ),
    );
  }

  Widget _buildScaffold() {
    return FutureBuilder(
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          Response res = snapshot.data as Response;
          var body = jsonDecode(res.body);
          return ListView.builder(
            itemCount: body['conversation'].length,
            itemBuilder: (context, index) => _buildChatRoomTile(
                ChatRoom.fromHomeJson(body['conversation'][index])),
          );
        },
        future: ChatDatabaseService.getChatRooms(_user!.uid));
  }

  ListTile _buildChatRoomTile(ChatRoom room) => ListTile(
        // leading: CircleAvatar(
        //   backgroundImage:
        //       NetworkImage(room.imgUrl == null ? '' : room.imgUrl!),
        // ),
        title: Text(room.name),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => Chat(room))),
      );
}
