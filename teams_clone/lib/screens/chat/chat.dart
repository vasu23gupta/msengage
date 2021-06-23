import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/ChatMessage.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/chat/chat_details.dart';
import 'package:teams_clone/screens/more/calendar.dart';
import 'package:teams_clone/services/chat.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:url_launcher/url_launcher.dart';

class Chat extends StatefulWidget {
  Chat(this.room);
  final ChatRoom room;
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  late ChatRoom _room;
  User? _user;
  TextEditingController _enterMsgController = TextEditingController();
  PlatformFile? pFile;
  bool _uploading = false;
  bool _loading = true;
  late double _h;
  late double _w;
  ScrollController _scrollController = ScrollController();
  final _filter = ProfanityFilter();
  late Stream<dynamic> _chatStream;
  String _lastMsgBy = '';

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    _room = widget.room;
    _chatStream = streamSocket.getResponse;
    _getRoom();
  }

  @override
  void dispose() {
    super.dispose();
    socket.emit("unsubscribe", {"room": _room.roomId});
  }

  Future _getRoom() async {
    _room = await ChatDatabaseService.getChatRoomByRoomId(_room.roomId);
    socket.emit("subscribe", {"room": _room.roomId});
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    _h = MediaQuery.of(context).size.height;
    _w = MediaQuery.of(context).size.width;
    return _loading
        ? Center(child: CircularProgressIndicator())
        : DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: _buildAppBar(),
              body: TabBarView(
                children: [
                  _buildChatTab(),
                  ListView(
                    children: <Widget>[
                      ListTile(
                        leading:
                            Icon(Icons.calendar_today, color: PURPLE_COLOR),
                        title: Text("Add an event"),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => Calendar(room: _room))),
                      ),
                      ListTile(
                        leading: Icon(Icons.info),
                        title: Text("Chat details"),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => ChatDetails(_room))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }

  AppBar _buildAppBar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.black),
      title: TextButton(
        child: Text(_room.name,
            style: TextStyle(color: Colors.black, fontSize: 17)),
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ChatDetails(_room))),
      ),
      bottom: TabBar(
        labelColor: PURPLE_COLOR,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
        indicatorColor: PURPLE_COLOR,
        unselectedLabelColor: Colors.black,
        tabs: [
          Tab(text: "CHAT"),
          Tab(text: "DASHBOARD"),
        ],
      ),
    );
  }

  ListView _buildChatTab() => ListView(
        reverse: true,
        children: [
          _buildBottomRow(),
          StreamBuilder(
            stream: _chatStream,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                var json = jsonDecode(jsonEncode(snapshot.data))['message'];
                ChatMessage cm = ChatMessage.fromJson(json);
                if (_room.messages.last.id != cm.id) _room.messages.add(cm);
              }
              return Container(
                height: _h * 0.8,
                child: ListView(
                    reverse: true,
                    controller: _scrollController,
                    shrinkWrap: true,
                    children: _room.messages
                        .map((e) => _buildChatMessageTile(e))
                        .toList()
                        .reversed
                        .toList()),
              );
            },
          ),
        ],
      );

  Container _buildBottomRow() => Container(
        height: _h * 0.08,
        alignment: Alignment.bottomCenter,
        color: Theme.of(context).bottomAppBarColor,
        padding: const EdgeInsets.only(bottom: 10, top: 10),
        child: Row(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: Icon(Icons.add, size: 20),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                primary: PURPLE_COLOR,
                minimumSize: Size(25, 25),
              ),
            ),
            SizedBox(
              width: _w * 0.75,
              child: TextField(
                enabled: pFile == null,
                controller: _enterMsgController,
                decoration: InputDecoration(
                    suffixIcon: _uploading
                        ? CircularProgressIndicator()
                        : IconButton(
                            icon: Icon(Icons.close, color: Colors.black),
                            onPressed: () {
                              _enterMsgController.clear();
                              if (pFile != null && !_uploading)
                                setState(() => pFile = null);
                            },
                          ),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    hintText: pFile == null ? "Enter message" : pFile!.name),
              ),
            ),
            IconButton(
              onPressed: _sendMessage,
              icon: Icon(Icons.send),
              color: PURPLE_COLOR,
            )
          ],
        ),
      );

  Future<void> _sendMessage() async {
    String msg = _enterMsgController.text;
    msg = msg.trim();
    Response res;
    if (pFile != null) {
      msg = pFile!.name;
      _uploading = true;
      UploadTask? task = FirebaseStorage.instance
          .ref()
          .child(_room.roomId)
          .child(pFile!.name)
          .putFile(File(pFile!.path!));
      await task.then((TaskSnapshot snapshot) {});
      _uploading = false;
    }
    if (msg.isNotEmpty) {
      if (_room.censoring) msg = _filter.censor(msg);

      res = await ChatDatabaseService.sendMessage(
          msg, _room.roomId, _user!.uid, pFile != null);

      if (res.statusCode == 200) {
        _enterMsgController.clear();
        if (pFile != null) setState(() => pFile = null);
      }
    }
  }

  Widget _buildChatMessageTile(ChatMessage msg) =>
      msg.userId == _user!.uid ? _buildMyMsgTile(msg) : _buildOtherMsgTile(msg);

  Widget _buildMyMsgTile(ChatMessage msg) {
    Widget res = Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: _w * 0.8),
        decoration: BoxDecoration(
            color: PURPLE_COLOR,
            borderRadius: BorderRadius.all(Radius.circular(5))),
        margin: const EdgeInsets.fromLTRB(2, 2, 8, 2),
        padding: const EdgeInsets.all(6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg.isMedia)
              IconButton(
                onPressed: () async {
                  if (msg.isMedia)
                    await launch(await FirebaseStorage.instance
                        .ref()
                        .child(_room.roomId)
                        .child(msg.msg)
                        .getDownloadURL());
                },
                icon: Icon(Icons.download),
              ),
            Flexible(
              child: Text(
                msg.msg,
                style: TextStyle(color: Colors.white, fontSize: _w * 0.045),
              ),
            ),
          ],
        ),
      ),
    );
    _lastMsgBy = msg.userId;
    return res;
  }

  Widget _buildOtherMsgTile(ChatMessage msg) {
    Widget res = Container(
      alignment: Alignment.centerLeft,
      margin: _lastMsgBy == msg.userId
          ? EdgeInsets.only(left: 6)
          : EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: Row(
        children: [
          _lastMsgBy == msg.userId
              ? Container(width: 40)
              : _room.users[msg.userId]!.icon,
          Container(
            constraints: BoxConstraints(maxWidth: _w * 0.8),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.all(Radius.circular(5))),
            margin: const EdgeInsets.fromLTRB(4, 2, 2, 2),
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lastMsgBy == msg.userId
                    ? Container(width: 0)
                    : Text(_room.users[msg.userId]!.name),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        msg.msg,
                        style: TextStyle(
                            color: Colors.black, fontSize: _w * 0.045),
                      ),
                    ),
                    if (msg.isMedia)
                      IconButton(
                        onPressed: () async {
                          if (msg.isMedia)
                            await launch(await FirebaseStorage.instance
                                .ref()
                                .child(_room.roomId)
                                .child(msg.msg)
                                .getDownloadURL());
                        },
                        icon: Icon(Icons.download),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    _lastMsgBy = msg.userId;
    return res;
  }

  Future<void> _pickFile() async {
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles();
    _enterMsgController.clear();
    if (pickedFile != null) setState(() => pFile = pickedFile.files.first);
  }
}
