import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide Coords;
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/ChatMessage.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/chat/chat_details.dart';
import 'package:teams_clone/screens/chat/pick_location.dart';
import 'package:teams_clone/screens/meet/meet.dart';
import 'package:teams_clone/screens/more/calendar.dart';
import 'package:teams_clone/services/chat.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_launcher/map_launcher.dart';

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
  PlatformFile? _pFile;
  bool _uploading = false;
  bool _loading = true;
  late double _h;
  late double _w;
  ScrollController _scrollController = ScrollController();
  final _filter = ProfanityFilter();
  late Stream<dynamic> _chatStream;
  String _lastMsgBy = '';
  bool _showMediaSheet = false;
  String _msgType = "text";
  Map<String, dynamic>? _locationResult;

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
      iconTheme: APPBAR_ICON_THEME,
      title: TextButton(
        child: Text(_room.name, style: APPBAR_TEXT_STYLE),
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ChatDetails(_room))),
      ),
      actions: [
        IconButton(
            onPressed: () =>
                joinMeeting(_room.roomId, _user!, name: _room.name),
            icon: Icon(Icons.video_call_outlined)),
        PopupMenuButton(
          onSelected: (choice) async {
            switch (choice) {
              case 'Chat details':
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ChatDetails(_room)));
                break;
            }
          },
          icon: Icon(Icons.more_vert),
          itemBuilder: (context) => ['Chat details']
              .map(
                  (choice) => PopupMenuItem(child: Text(choice), value: choice))
              .toList(),
        ),
      ],
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
          _showMediaSheet ? _buildMediaSheet() : Container(),
          _buildInputRow(),
          StreamBuilder(
            stream: _chatStream,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                var json = jsonDecode(jsonEncode(snapshot.data))['message'];
                ChatMessage cm = ChatMessage.fromJson(json);
                if (_room.messages.isEmpty || _room.messages.last.id != cm.id)
                  _room.messages.add(cm);
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
                      .toList(),
                ),
              );
            },
          ),
        ],
      );

  Wrap _buildMediaSheet() {
    return Wrap(
      children: [
        _buildAttachImageButton(),
        _buildAttachFileButton(),
        _buildAttachLocationButton()
      ],
    );
  }

  Padding _buildAttachImageButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _pickImage,
            child: Icon(
              Icons.image_outlined,
              color: Colors.green,
              size: 30,
            ),
            style: ElevatedButton.styleFrom(
                primary: Colors.white, fixedSize: Size(40, 50)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Image"),
          )
        ],
      ),
    );
  }

  Padding _buildAttachFileButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _pickFile,
            child: Icon(
              Icons.attachment_rounded,
              color: Colors.blue,
              size: 30,
            ),
            style: ElevatedButton.styleFrom(
                primary: Colors.white, fixedSize: Size(40, 50)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("File"),
          )
        ],
      ),
    );
  }

  Padding _buildAttachLocationButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _pickLocation,
            child: Icon(
              Icons.location_on_outlined,
              color: Colors.red,
              size: 30,
            ),
            style: ElevatedButton.styleFrom(
                primary: Colors.white, fixedSize: Size(40, 50)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Location"),
          )
        ],
      ),
    );
  }

  Container _buildInputRow() => Container(
        height: _h * 0.08,
        alignment: Alignment.bottomCenter,
        color: Theme.of(context).bottomAppBarColor,
        padding: const EdgeInsets.only(bottom: 10, top: 10),
        child: Row(
          children: [
            ElevatedButton(
              onPressed: () =>
                  setState(() => _showMediaSheet = !_showMediaSheet),
              child: Icon(_showMediaSheet ? Icons.close : Icons.add, size: 20),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                primary: PURPLE_COLOR,
                minimumSize: Size(_w * 0.06, _w * 0.06),
              ),
            ),
            SizedBox(
              width: _w * 0.63,
              child: TextField(
                // minLines: null,
                // maxLines: null,
                // expands: true,
                enabled: _msgType == "text",
                controller: _enterMsgController,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  hintText: _msgType == "text"
                      ? "Enter message"
                      : _msgType == "location"
                          ? _locationResult!['place']
                          : _pFile!.name,
                ),
              ),
            ),
            _uploading
                ? Container(
                    child: CircularProgressIndicator(),
                    height: _w * 0.056,
                    width: _w * 0.056,
                    margin: const EdgeInsets.all(10),
                  )
                : IconButton(
                    icon: Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      _enterMsgController.clear();
                      _pFile = null;
                      setState(() => _msgType = "text");
                    },
                  ),
            !_uploading
                ? IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send),
                    color: PURPLE_COLOR,
                  )
                : Container()
          ],
        ),
      );

  Future<void> _sendMessage() async {
    String msg = _enterMsgController.text.trim();
    Response res;
    switch (_msgType) {
      case "text":
        if (_room.censoring) msg = _filter.censor(msg);
        break;
      case "file":
        msg = _pFile!.name;
        setState(() => _uploading = true);
        UploadTask? task = FirebaseStorage.instance
            .ref()
            .child(_room.roomId)
            .child(_pFile!.name)
            .putFile(File(_pFile!.path!));
        await task.then((TaskSnapshot snapshot) {});
        setState(() => _uploading = false);
        break;
      case "image":
        setState(() => _uploading = true);
        msg = await ImageDatabaseService.uploadImage(
            _pFile!.path!, _room.censoring);
        setState(() => _uploading = false);
        break;
      case "location":
        msg = jsonEncode(_locationResult);
        break;
    }
    if (msg.isNotEmpty) {
      res = await ChatDatabaseService.sendMessage(
          msg, _room.roomId, _user!.uid, _msgType);

      if (res.statusCode == 200) {
        _enterMsgController.clear();
        _pFile = null;
        setState(() => _msgType = "text");
      }
    }
  }

  Widget _buildChatMessageTile(ChatMessage msg) =>
      msg.userId == _user!.uid ? _buildMyMsgTile(msg) : _buildOtherMsgTile(msg);

  Widget _buildMyMsgTile(ChatMessage msg) {
    Map<String, dynamic>? location;
    LatLng? coords;
    if (msg.type == "location") {
      location = jsonDecode(msg.msg);
      coords = LatLng(location!['lat'], location['lon']);
    }

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
            if (msg.type == "file")
              IconButton(
                onPressed: () async {
                  await launch(await FirebaseStorage.instance
                      .ref()
                      .child(_room.roomId)
                      .child(msg.msg)
                      .getDownloadURL());
                },
                icon: Icon(Icons.download),
              ),
            if (msg.type == "image")
              Image(
                image: ImageDatabaseService.getImageByImageId(msg.msg),
                height: _h * 0.3,
                fit: BoxFit.contain,
              ),
            if (msg.type == "file" || msg.type == "text")
              Flexible(
                child: Text(
                  msg.msg,
                  style: TextStyle(color: Colors.white, fontSize: _w * 0.045),
                ),
              ),
            if (msg.type == "location")
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: _h * 0.2,
                    width: _w * 0.6,
                    child: FlutterMap(
                      options: MapOptions(
                        onTap: (latlng) async => await MapLauncher.showMarker(
                          title: location!['place'],
                          mapType: MapType.google,
                          coords: Coords(coords!.latitude, coords.longitude),
                        ),
                        allowPanning: false,
                        center: coords,
                      ),
                      layers: [
                        TileLayerOptions(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayerOptions(
                          markers: [
                            Marker(
                              point: coords!,
                              builder: (_) => Icon(
                                Icons.location_on_rounded,
                                color: PURPLE_COLOR,
                                size: _w * 0.1,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  Container(
                    width: _w * 0.6,
                    child: Text(
                      location!['place'],
                      style:
                          TextStyle(color: Colors.white, fontSize: _w * 0.045),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
    _lastMsgBy = msg.userId;
    return res;
  }

  Widget _buildOtherMsgTile(ChatMessage msg) {
    Map<String, dynamic>? location;
    LatLng? coords;
    if (msg.type == "location") {
      location = jsonDecode(msg.msg);
      coords = LatLng(location!['lat'], location['lon']);
    }
    Widget res = Container(
      alignment: Alignment.centerLeft,
      margin: _lastMsgBy == msg.userId
          ? EdgeInsets.only(left: 6)
          : EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _getUserIcon(msg),
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
                    : _room.users[msg.userId] == null
                        ? Text("User")
                        : Text(_room.users[msg.userId]!.name),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (msg.type == "file" || msg.type == "text")
                      Flexible(
                        child: Text(msg.msg,
                            style: TextStyle(
                                color: Colors.black, fontSize: _w * 0.045)),
                      ),
                    if (msg.type == "image")
                      Image(
                        image: ImageDatabaseService.getImageByImageId(msg.msg),
                        height: _h * 0.3,
                        fit: BoxFit.contain,
                      ),
                    if (msg.type == "file")
                      IconButton(
                        onPressed: () async {
                          await launch(await FirebaseStorage.instance
                              .ref()
                              .child(_room.roomId)
                              .child(msg.msg)
                              .getDownloadURL());
                        },
                        icon: Icon(Icons.download),
                      ),
                    if (msg.type == "location")
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: _h * 0.2,
                            width: _w * 0.6,
                            child: FlutterMap(
                              options: MapOptions(
                                onTap: (latlng) async =>
                                    await MapLauncher.showMarker(
                                  title: location!['place'],
                                  mapType: MapType.google,
                                  coords: Coords(
                                      coords!.latitude, coords.longitude),
                                ),
                                allowPanning: false,
                                center: coords,
                              ),
                              layers: [
                                TileLayerOptions(
                                  urlTemplate:
                                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  subdomains: ['a', 'b', 'c'],
                                ),
                                MarkerLayerOptions(
                                  markers: [
                                    Marker(
                                      point: coords!,
                                      builder: (_) => Icon(
                                        Icons.location_on_rounded,
                                        color: PURPLE_COLOR,
                                        size: _w * 0.1,
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                          Container(
                            width: _w * 0.6,
                            child: Text(
                              location!['place'],
                              style: TextStyle(
                                  color: Colors.black, fontSize: _w * 0.045),
                            ),
                          ),
                        ],
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

  Widget _getUserIcon(ChatMessage msg) {
    return _lastMsgBy == msg.userId
        ? Container(width: 40)
        : _room.users[msg.userId] == null
            ? CircleAvatar(child: Text("U"))
            : _room.users[msg.userId]!.imgUrl == null ||
                    _room.users[msg.userId]!.imgUrl!.isEmpty
                ? CircleAvatar(
                    child: Text(_room.users[msg.userId]!.name
                        .substring(0, 2)
                        .toUpperCase()))
                : CircleAvatar(
                    backgroundImage: ImageDatabaseService.getImageByImageId(
                        _room.users[msg.userId]!.imgUrl!));
  }

  Future<void> _pickFile() async {
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles();
    _enterMsgController.clear();
    if (pickedFile != null)
      setState(() {
        _pFile = pickedFile.files.first;
        _msgType = "file";
      });
  }

  Future<void> _pickImage() async {
    FilePickerResult? pickedFile = await FilePicker.platform
        .pickFiles(allowMultiple: false, type: FileType.image);
    _enterMsgController.clear();
    if (pickedFile != null)
      setState(() {
        _pFile = pickedFile.files.first;
        _msgType = "image";
      });
  }

  Future<void> _pickLocation() async {
    Map<String, dynamic>? result = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PickLocation()));
    if (result != null)
      setState(() {
        _msgType = "location";
        _locationResult = result;
      });
  }
}
