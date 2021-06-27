import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/CalendarEvent.dart';
import 'package:teams_clone/models/ChatMessage.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/services/database.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
  }

  User? _user;
  // late double _w;
  // late double _h;
  // bool _loading = true;
  List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatRoom> _rooms = <ChatRoom>[];
  List<CalendarEvent> _events = <CalendarEvent>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        title: TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: Navigator.of(context).pop,
            ),
            hintText: "Search",
            fillColor: Colors.grey[200],
            filled: true,
          ),
          onChanged: (val) async {
            val = val.trim();
            if (val.length > 0) {
              Map<String, dynamic> result =
                  await UserDBService.search(val, _user!.uid);
              _rooms = result['rooms'];
              _events = result['events'];
              _messages = result['messages'];
            }
          },
        ),
      ),
      //body: ,
    );
  }
}
