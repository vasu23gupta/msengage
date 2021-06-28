import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:teams_clone/models/ChatMessage.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/chat/chat.dart';
import 'package:teams_clone/screens/chat/name_image.dart';
import 'package:teams_clone/screens/search.dart';
import 'package:teams_clone/services/chat.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';

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
    _getRooms();
    connectAndListen();
  }

  Future _getRooms() async {
    rooms = await ChatDatabaseService.getChatRooms(_user!.uid);
    setState(() => _loading = false);
  }

  User? _user;
  late double _w;
  late double _h;
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    _w = MediaQuery.of(context).size.width;
    _h = MediaQuery.of(context).size.height;
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
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _getRooms,
              child: ListView.builder(
                itemCount: rooms.length,
                itemBuilder: (context, index) =>
                    _buildChatRoomTile(rooms[index]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ChatNameImage())),
        child: Icon(Icons.create),
      ),
    );
  }

  // Widget _buildScaffold() {
  //   return FutureBuilder(
  //     future: ChatDatabaseService.getChatRooms(_user!.uid),
  //     builder: (context, snapshot) {
  //       if (!snapshot.hasData)
  //         return Center(child: CircularProgressIndicator());

  //       rooms = snapshot.data as List<ChatRoom>;
  //       return RefreshIndicator(
  //         onRefresh: () async => setState(() {}),
  //         child: ListView.builder(
  //           itemCount: rooms.length,
  //           itemBuilder: (context, index) => _buildChatRoomTile(rooms[index]),
  //         ),
  //       );
  //     },
  //   );
  // }

  Container _buildChatRoomTile(ChatRoom room) {
    ChatMessage? msg = room.messages.isEmpty ? null : room.messages[0];
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 0.5, color: Colors.grey)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: _w * 0.07,
          backgroundColor: Colors.white,
          backgroundImage: room.imgUrl == null || room.imgUrl!.isEmpty
              ? ExactAssetImage(DEFAULT_GROUP_IMG)
              : ImageDatabaseService.getImageByImageId(room.imgUrl!)
                  as ImageProvider,
        ),
        title: Text(room.name, style: TextStyle(fontSize: _w * 0.04)),
        subtitle: msg != null
            ? Padding(
                padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                child: RichText(
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  text: TextSpan(
                    style: TextStyle(
                        fontSize: _w * 0.035, color: Colors.grey[600]),
                    children: [
                      TextSpan(text: room.users[msg.userId]!.name),
                      TextSpan(text: ": "),
                      TextSpan(
                          text: room.messages[0].type == "image" ||
                                  room.messages[0].type == "location"
                              ? room.messages[0].type
                              : room.messages[0].msg)
                    ],
                  ),
                ),
              )
            : null,
        trailing: msg != null
            ? Text(isSameDay(msg.dateTime, DateTime.now())
                ? "${msg.dateTime.hour}:${msg.dateTime.minute}"
                : "${msg.dateTime.day}/${msg.dateTime.month}")
            : Container(),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => Chat(room))),
      ),
    );
  }
}
