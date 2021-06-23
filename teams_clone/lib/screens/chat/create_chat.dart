import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/chat/chat.dart';
import 'package:teams_clone/services/database.dart';

class CreateChat extends StatefulWidget {
  const CreateChat({Key? key}) : super(key: key);

  @override
  _CreateChatState createState() => _CreateChatState();
}

class _CreateChatState extends State<CreateChat> {
  List<String> _emails = [];
  HashMap<String, String> _emailsAndIds = new HashMap();
  TextEditingController _addEmailController = TextEditingController();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
  }

  Iterable<Widget> get _tagWidgets sync* {
    for (final String tag in _emails)
      yield Padding(
        padding: const EdgeInsets.all(4.0),
        child: InputChip(
          label: Text(tag),
          onDeleted: () => setState(
              () => _emails.removeWhere((String entry) => entry == tag)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New chat"),
        actions: [
          FlatButton(
            onPressed: () async {
              String? roomId = await ChatDatabaseService.createNewChatRoom(
                  _emailsAndIds.values.toList(), "New Chat", _user!.uid);
              if (roomId != null)
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => Chat(ChatRoom(roomId: roomId))));
            },
            child: Text("NEXT"),
          )
        ],
      ),
      body: Column(
        //mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _addEmailController,
            decoration: InputDecoration(hintText: "Enter Emails"),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () async {
                String email = _addEmailController.text;
                if (email.isNotEmpty &&
                    !_emails.contains(email) &&
                    _user!.email != email) {
                  String? id = await UserDBService.getUserIdFromEmail(email);
                  if (id != null) {
                    _emails.add(email);
                    _emailsAndIds.putIfAbsent(email, () => id);
                    setState(() => _addEmailController.clear());
                  } else
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("User doesnt exist")));
                } else
                  setState(() => _addEmailController.clear());
              },
              child: Text('Add Email'),
            ),
          ),
          Wrap(children: _tagWidgets.toList()),
        ],
      ),
    );
  }
}
