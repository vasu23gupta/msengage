import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/chat/chat.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';

class AddUsers extends StatefulWidget {
  final ChatRoom room;
  const AddUsers({required this.room});

  @override
  _AddUsersState createState() => _AddUsersState();
}

class _AddUsersState extends State<AddUsers> {
  List<String> _newEmails = [];
  HashSet<String> _existingUserEmails = HashSet();
  HashMap<String, String> _newEmailsAndIds = new HashMap();
  TextEditingController _addEmailController = TextEditingController();
  User? _user;
  late ChatRoom _room;

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    _room = widget.room;
    if (_room.roomId.isNotEmpty)
      _room.users.forEach((id, user) => _existingUserEmails.add(user.email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildEmailTextField(),
          _buildAddEmailButton(),
          Wrap(children: _tagWidgets.toList()),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text("New chat", style: APPBAR_TEXT_STYLE),
      iconTheme: APPBAR_ICON_THEME,
      actions: [_buildCreateChatButton()],
    );
  }

  TextButton _buildCreateChatButton() {
    return TextButton(
      onPressed: _createChat,
      child: Text("NEXT"),
      style: TextButton.styleFrom(primary: PURPLE_COLOR),
    );
  }

  void _createChat() async {
    if (_room.roomId.isEmpty) {
      String? roomId = await ChatDatabaseService.createNewChatRoom(
          _newEmailsAndIds.values.toList(), _room, _user!.uid);
      if (roomId != null)
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => Chat(ChatRoom(roomId: roomId))));
    } else {
      bool done = await ChatDatabaseService.addUsersToChatRoom(
          _room.roomId, _newEmailsAndIds.values.toList());
      if (done) {
        Navigator.of(context).pop(); //add users
        Navigator.of(context).pop(); //chat details
        Navigator.of(context).pop(); //chat
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => Chat(_room)));
      }
    }
  }

  TextField _buildEmailTextField() {
    return TextField(
      controller: _addEmailController,
      decoration: InputDecoration(hintText: "Enter Emails"),
    );
  }

  Padding _buildAddEmailButton() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: _addUser,
        child: Text('Add Email'),
      ),
    );
  }

  Future _addUser() async {
    String email = _addEmailController.text;
    if (email.isNotEmpty &&
        !_newEmailsAndIds.containsKey(email) &&
        _user!.email != email &&
        !_existingUserEmails.contains(email)) {
      String? id = await UserDBService.getUserIdFromEmail(email);
      if (id != null) {
        _newEmails.add(email);
        _newEmailsAndIds[email] = id;
        setState(() => _addEmailController.clear());
      } else
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("User doesnt exist")));
    } else
      setState(() => _addEmailController.clear());
  }

  Iterable<Widget> get _tagWidgets sync* {
    for (final String tag in _newEmails)
      yield Padding(
        padding: const EdgeInsets.all(4.0),
        child: InputChip(
          label: Text(tag),
          onDeleted: () => setState(() {
            _newEmails.removeWhere((String entry) => entry == tag);
            _newEmailsAndIds.remove(tag);
          }),
        ),
      );
  }
}
