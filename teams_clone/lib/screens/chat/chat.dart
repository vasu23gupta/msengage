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
import 'package:teams_clone/services/chat.dart';
import 'package:teams_clone/services/database.dart';
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

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    _room = widget.room;
    print(_room.roomId);
    socket.emit("subscribe", {"room": _room.roomId});
  }

  @override
  void dispose() {
    super.dispose();
    socket.emit("unsubscribe", {"room": _room.roomId});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: ChatDatabaseService.getChatRoomByRoomId(_room.roomId),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          _room = snapshot.data as ChatRoom;
          return Scaffold(
            appBar: AppBar(
              title: Text(_room.name),
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StreamBuilder(
                  stream: streamSocket.getResponse,
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      print("snapshot data: " + snapshot.data.toString());
                      var json =
                          jsonDecode(jsonEncode(snapshot.data))['message'];
                      print(json);
                      ChatMessage cm = ChatMessage.fromJson(json);
                      print(cm.id);
                      print(cm.msg);
                      print(cm.roomId);
                      print(cm.userId);
                      print(cm.isMedia);
                      _room.messages.add(cm);
                    }
                    return ListView(
                        shrinkWrap: true,
                        children: _room.messages
                            .map((e) => _buildChatMessageTile(e))
                            .toList());
                  },
                ),
                _buildBottomRow(),
              ],
            ),
          );
        });
  }

  Row _buildBottomRow() => Row(
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
              width: 250,
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
                    setState(() {
                      _enterMsgController.clear();
                      pFile = null;
                    });
                  },
                ),
          SizedBox(
              height: 30,
              child: FloatingActionButton(
                  heroTag: null,
                  onPressed: _sendMessage,
                  child: Icon(Icons.send, size: 18)))
        ],
      );

  Future _sendMessage() async {
    String msg = _enterMsgController.text;
    msg = msg.trim();
    Response res;
    UploadTask? task;
    if (pFile != null) {
      msg = pFile!.name;
      task = FirebaseStorage.instance
          .ref()
          .child(_room.roomId)
          .child(pFile!.name)
          .putFile(File(pFile!.path!));
      setState(() => _uploading = true);
      await task.whenComplete(() => null);
      setState(() => _uploading = false);
    }
    if (msg.isNotEmpty) {
      if (task != null) await task.whenComplete(() => null);
      res = await ChatDatabaseService.sendMessage(
          msg, _room.roomId, _user!.uid, pFile != null);
      socket.emit(
        "new message",
        jsonEncode({
          'room': _room.roomId,
          'message': msg,
          'postedByUser': _user!.uid,
          'isMedia': pFile != null,
        }),
      );
      if (res.statusCode == 200) {
        setState(() {
          _enterMsgController.clear();
          pFile = null;
        });
      }
    }
  }

  Widget _buildChatMessageTile(ChatMessage msg) {
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
                    if (await canLaunch(url))
                      await launch(url);
                    else
                      print(url);
                  }
                },
                icon: Icon(Icons.download))
            : SizedBox(height: 0, width: 0),
        title: Text(msg.msg),
        tileColor:
            msg.userId == _user!.uid ? Colors.indigo[300] : Colors.grey[300],
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles();
    if (pickedFile != null)
      setState(() {
        pFile = pickedFile.files.first;
        _enterMsgController.clear();
      });
  }
}
