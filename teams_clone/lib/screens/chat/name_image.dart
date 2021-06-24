import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/chat/add_users.dart';
import 'package:teams_clone/shared/constants.dart';

class ChatNameImage extends StatefulWidget {
  const ChatNameImage({Key? key}) : super(key: key);

  @override
  _ChatNameImageState createState() => _ChatNameImageState();
}

class _ChatNameImageState extends State<ChatNameImage> {
  ChatRoom _room = ChatRoom(roomId: '');
  TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New chat", style: APPBAR_TEXT_STYLE),
        iconTheme: APPBAR_ICON_THEME,
        actions: [
          TextButton(
            onPressed: () {
              _room.name = _controller.text;
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AddUsers(room: _room)));
            },
            child: Text("NEXT"),
            style: TextButton.styleFrom(primary: PURPLE_COLOR),
          )
        ],
      ),
      body: ListTile(
        leading: GestureDetector(
          onTap: _pickFile,
          child: _room.imgUrl == null
              ? CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.add_a_photo_outlined, color: Colors.black),
                  backgroundColor: Colors.black26,
                )
              : CircleAvatar(
                  radius: 30,
                  backgroundImage: Image.file(File(_room.imgUrl!)).image,
                ),
        ),
        title: TextField(
          controller: _controller,
          decoration: InputDecoration(
              hintText: "Chat name", focusedBorder: UnderlineInputBorder()),
        ),
        subtitle: Text("Please provide a group name and photo"),
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles();
    if (pickedFile != null)
      setState(() => _room.imgUrl = pickedFile.files.first.path);
  }
}
