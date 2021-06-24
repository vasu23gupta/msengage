import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/chat/chat.dart';
import 'package:teams_clone/screens/chat/add_users.dart';
import 'package:teams_clone/screens/chat/name_image.dart';
import 'package:teams_clone/screens/search.dart';
import 'package:teams_clone/services/chat.dart';
import 'package:teams_clone/services/database.dart';

class ChatHome extends StatefulWidget {
  const ChatHome({Key? key}) : super(key: key);

  @override
  _ChatHomeState createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  List<ChatRoom> _rooms = [];
  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    connectAndListen();
  }

  User? _user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        titleSpacing: 6,
        title: GestureDetector(
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => Search())),
          child: TextField(
            enabled: false,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search),
              hintText: "Search",
              fillColor: Colors.grey[200],
              filled: true,
            ),
          ),
        ),
      ),
      body: _buildScaffold(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ChatNameImage())),
        child: Icon(Icons.create),
      ),
    );
  }

  Widget _buildScaffold() {
    return FutureBuilder(
      future: ChatDatabaseService.getChatRooms(_user!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        _rooms = snapshot.data as List<ChatRoom>;
        return ListView.builder(
          itemCount: _rooms.length,
          itemBuilder: (context, index) => _buildChatRoomTile(_rooms[index]),
        );
      },
    );
  }

  ListTile _buildChatRoomTile(ChatRoom room) => ListTile(
        leading: room.icon,
        title: Text(room.name),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => Chat(room))),
      );
}
