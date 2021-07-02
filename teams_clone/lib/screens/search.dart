import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/CalendarEvent.dart';
import 'package:teams_clone/models/ChatMessage.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/chat/chat.dart';
import 'package:teams_clone/screens/chat/chat_home.dart';
import 'package:teams_clone/screens/more/event_details.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';

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
  late double _w;
  late double _h;
  // bool _loading = true;
  List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatRoom> _rooms = <ChatRoom>[];
  List<CalendarEvent> _events = <CalendarEvent>[];
  TextEditingController _controller = TextEditingController();
  int _selected = 0;
  List<String> _chipNames = ['ALL', 'CHATS', 'MESSAGES', 'EVENTS'];
  List<List<Widget>> _widgets = List.filled(4, []);

  List<Container> _buildChats() {
    return _rooms
        .map((e) => Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border:
                    Border(bottom: BorderSide(width: 0.5, color: Colors.grey)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: e.imgUrl == null || e.imgUrl!.isEmpty
                      ? ExactAssetImage(DEFAULT_GROUP_IMG)
                      : ImageDatabaseService.getImageByImageId(e.imgUrl!)
                          as ImageProvider,
                ),
                title: Text(e.name, style: TextStyle(fontSize: _w * 0.05)),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => Chat(e))),
              ),
            ))
        .toList();
  }

  List<Widget> _buildEvents() => _events
      .map((e) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: Offset(0, 2), // changes position of shadow
                  ),
                ],
              ),
              child: ListTile(
                title: Text(e.title, style: TextStyle(fontSize: _w * 0.05)),
                subtitle: Text(
                  "${e.startDate.day} ${MONTHS_3CHAR[e.startDate.month - 1]} ${e.startDate.year}, ${e.startDate.hour}:${e.startDate.minute} - ${e.endDate.day} ${MONTHS_3CHAR[e.endDate.month - 1]} ${e.endDate.year}, ${e.endDate.hour}:${e.endDate.minute}",
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => EventDetails(e))),
              ),
            ),
          ))
      .toList();

  // List<Widget> _buildMessages() => _messages
  //     .map((e) => Container(
  //           constraints: BoxConstraints(maxWidth: _w * 0.8),
  //           decoration: BoxDecoration(
  //               border: Border.all(color: PURPLE_COLOR),
  //               borderRadius: BorderRadius.all(Radius.circular(5))),
  //           margin: const EdgeInsets.fromLTRB(8, 6, 6, 6),
  //           padding: const EdgeInsets.all(6.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 rooms
  //                     .firstWhere((element) => element.roomId == e.roomId)
  //                     .name,
  //                 style: TextStyle(
  //                     fontWeight: FontWeight.bold, fontSize: _w * 0.04),
  //               ),
  //               Text(
  //                 e.appUser!.name,
  //                 style: TextStyle(fontSize: _w * 0.04),
  //               ),
  //               Row(
  //                 //mainAxisSize: MainAxisSize.min,
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   if (e.type == "file" || e.type == "text")
  //                     Flexible(
  //                       child: Text(e.msg,
  //                           style: TextStyle(
  //                               color: Colors.black, fontSize: _w * 0.045)),
  //                     ),
  //                   if (e.type == "file")
  //                     IconButton(
  //                       onPressed: () async {
  //                         await launch(await FirebaseStorage.instance
  //                             .ref()
  //                             .child(e.roomId)
  //                             .child(e.msg)
  //                             .getDownloadURL());
  //                       },
  //                       icon: Icon(Icons.download),
  //                     ),
  //                   Text(
  //                       "${e.dateTime.day}/${e.dateTime.month}, ${e.dateTime.hour}:${e.dateTime.minute}")
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ))
  //     .toList();

  List<Widget> _buildMessages() => _messages.map((e) {
        ChatRoom room =
            rooms.firstWhere((element) => element.roomId == e.roomId);
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(width: 0.5, color: Colors.grey)),
          ),
          child: ListTile(
            leading: _getUserIcon(e),
            title: Text("${e.appUser!.name}: ${e.msg}"),
            subtitle: Text(room.name),
            trailing: Text(
                "${e.dateTime.day}/${e.dateTime.month}, ${e.dateTime.hour}:${e.dateTime.minute}"),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => Chat(room))),
          ),
        );
      }).toList();

  @override
  Widget build(BuildContext context) {
    _w = MediaQuery.of(context).size.width;
    _h = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: TextField(
            controller: _controller,
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
            onChanged: _performSearch,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size(_w, 0.06 * _h),
          child: Row(
              children: _chipNames
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ActionChip(
                        label: Text(e,
                            style: TextStyle(
                                color: _selected == _chipNames.indexOf(e)
                                    ? Colors.white
                                    : Colors.black87)),
                        backgroundColor: _selected == _chipNames.indexOf(e)
                            ? PURPLE_COLOR
                            : Colors.grey[300],
                        onPressed: () =>
                            setState(() => _selected = _chipNames.indexOf(e)),
                      ),
                    ),
                  )
                  .toList()),
        ),
      ),
      body: ListView(
        children: _selected == 0
            ? [
                _widgets[1].length > 0
                    ? ListTile(
                        title: Text("Chats  (${_widgets[1].length} results)"),
                        trailing: Icon(Icons.keyboard_arrow_down_rounded),
                      )
                    : Container(),
                ..._widgets[1],
                _widgets[2].length > 0
                    ? ListTile(
                        title:
                            Text("Messages  (${_widgets[2].length} results)"),
                        trailing: Icon(Icons.keyboard_arrow_down_rounded),
                      )
                    : Container(),
                ..._widgets[2],
                _widgets[3].length > 0
                    ? ListTile(
                        title: Text("Events  (${_widgets[3].length} results)"),
                        trailing: Icon(Icons.keyboard_arrow_down_rounded),
                      )
                    : Container(),
                ..._widgets[3],
              ]
            : _widgets[_selected],
      ),
    );
  }

  Future<void> _performSearch(String val) async {
    val = val.trim();
    if (val.length > 0) {
      Map<String, dynamic> result = await UserDBService.search(val, _user!.uid);
      _rooms = result['rooms'];
      _events = result['events'];
      _messages = result['messages'];
      _widgets[1] = _buildChats();
      _widgets[2] = _buildMessages();
      _widgets[3] = _buildEvents();
      setState(() {});
    } else {
      _rooms.clear();
      _events.clear();
      _messages.clear();
      _widgets.forEach((e) => e.clear());
      setState(() {});
    }
  }

  Widget _getUserIcon(ChatMessage msg) {
    return msg.appUser!.imgUrl == null || msg.appUser!.imgUrl!.isEmpty
        ? CircleAvatar(
            child: Text(msg.appUser!.name.substring(0, 2).toUpperCase()))
        : CircleAvatar(
            backgroundImage:
                ImageDatabaseService.getImageByImageId(msg.appUser!.imgUrl!));
  }
}
