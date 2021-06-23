import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/chat/chat.dart';
import 'package:teams_clone/screens/home.dart';
import 'package:teams_clone/services/chat.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';

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
        iconTheme: IconThemeData(color: Colors.black),
        title: Text("Chat Details",
            style: TextStyle(color: Colors.black, fontSize: 17)),
      ),
      body: ListView(
        children: [
          SizedBox(
            child: _room.icon,
            height: 150,
            width: 150,
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text(_room.name),
            onTap: () => showDialog(
                context: context, builder: (_) => _buildChangeNameDialog()),
          ),
          ListTile(
            leading: Icon(Icons.report_gmailerrorred_rounded),
            title: Text("Profanity filtering"),
            trailing: Switch(
              activeColor: PURPLE_COLOR,
              onChanged: (val) async {
                bool prev = _room.censoring;
                setState(() => _room.censoring = val);
                bool changed = await ChatDatabaseService.changeRoomCensorship(
                    _room.roomId, _user!.uid, val);
                if (!changed) setState(() => _room.censoring = prev);
              },
              value: _room.censoring,
            ),
          ),
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
          ),
          ListTile(
            title: Text(
              "${_room.users.length} participants",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListView(
            shrinkWrap: true,
            children: _room.users.values
                .map((e) => ListTile(leading: e.icon, title: Text(e.name)))
                .toList(),
          )
        ],
      ),
    );
  }

  StatefulBuilder _buildChangeNameDialog() {
    return StatefulBuilder(
      builder: (context, setState) {
        TextEditingController controller = TextEditingController();
        controller.text = _room.name;
        bool loading = false;

        void changeName(String name) async {
          setState(() => loading = true);
          bool done = await ChatDatabaseService.changeRoomName(
              _room.roomId, _user!.uid, name);
          if (done) _room.name = name;
          int _count = 0;
          Navigator.popUntil(context, (route) => _count++ == 3);
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => Home()));
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => Chat(_room)));
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => ChatDetails(_room)));
        }

        List<Widget> buttons = [
          TextButton(
              onPressed: () => changeName("Chat"),
              child: Text("REMOVE", style: TextStyle(color: PURPLE_COLOR))),
          SizedBox(width: 30),
          TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text("CANCEL", style: TextStyle(color: PURPLE_COLOR))),
          TextButton(
              onPressed: () => changeName(controller.text),
              child: Text("OK", style: TextStyle(color: PURPLE_COLOR)))
        ];

        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          title: Text("Name group chat"),
          actions: loading ? [CircularProgressIndicator()] : buttons,
          content: TextField(controller: controller, enabled: !loading),
        );
      },
    );
  }
}
