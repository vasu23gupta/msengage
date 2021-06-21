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
        height: _h * 0.071,
        alignment: Alignment.bottomCenter,
        color: Theme.of(context).bottomAppBarColor,
        padding: const EdgeInsets.all(0.0),
        child: Row(
          children: [
            SizedBox(
              height: 30,
              child: FloatingActionButton(
                heroTag: null,
                onPressed: _pickFile,
                child: Icon(Icons.add),
              ),
            ),
            SizedBox(
                width: _w * 0.6,
                child: TextField(
                  enabled: pFile == null,
                  controller: _enterMsgController,
                  decoration: InputDecoration(
                      hintText: pFile == null ? "Enter message" : pFile!.name),
                )),
            _uploading
                ? CircularProgressIndicator()
                : IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      _enterMsgController.clear();
                      if (pFile != null && !_uploading)
                        setState(() => pFile = null);
                    },
                  ),
            SizedBox(
                height: 30,
                child: FloatingActionButton(
                    heroTag: null,
                    onPressed: _sendMessage,
                    child: Icon(Icons.send, size: 18)))
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

  Widget _buildChatMessageTile(ChatMessage msg) {
    bool isMine = msg.userId == _user!.uid;
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ListTile(
        trailing: msg.isMedia
            ? IconButton(
                onPressed: () async {
                  if (msg.isMedia) {
                    String url = await FirebaseStorage.instance
                        .ref()
                        .child(_room.roomId)
                        .child(msg.msg)
                        .getDownloadURL();
                    await launch(url);
                  }
                },
                icon: Icon(Icons.download))
            : SizedBox(height: 0, width: 0),
        title: Text(
          msg.msg,
          style: TextStyle(color: isMine ? Colors.white : Colors.black),
        ),
        tileColor: isMine ? PURPLE_COLOR : Colors.grey[300],
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles();
    _enterMsgController.clear();
    if (pickedFile != null) setState(() => pFile = pickedFile.files.first);
  }
}
