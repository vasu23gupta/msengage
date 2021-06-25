import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/chat/chat.dart';
import 'package:teams_clone/screens/chat/name_image.dart';
import 'package:teams_clone/screens/search.dart';
import 'package:teams_clone/services/chat.dart';
import 'package:teams_clone/services/database.dart';

class ChatHome extends StatefulWidget {
  const ChatHome({Key? key}) : super(key: key);

  @override
  _ChatHomeState createState() => _ChatHomeState();
}

List<ChatRoom> rooms = [];

class _ChatHomeState extends State<ChatHome> {
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

        rooms = snapshot.data as List<ChatRoom>;
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) => _buildChatRoomTile(rooms[index]),
          ),
        );
      },
    );
  }

  ListTile _buildChatRoomTile(ChatRoom room) => ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: room.imgUrl == null || room.imgUrl!.isEmpty
              ? ExactAssetImage("assets/default_group_icon.png")
              : NetworkImage(URL + "images/" + room.imgUrl!) as ImageProvider,
        ),
        title: Text(room.name),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => Chat(room))),
      );
}
