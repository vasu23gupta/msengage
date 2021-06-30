import 'dart:collection';
import 'package:teams_clone/models/AppUser.dart';
import 'package:teams_clone/models/CalendarEvent.dart';
import 'package:teams_clone/models/ChatMessage.dart';

/// A chat room or group or team.
class ChatRoom {
  /// unique room id
  late String _roomId;

  /// group name
  late String name;

  /// chat room icon url, can be null if no icon is set.
  String? imgUrl;

  /// list of messages, includes all messages downloaded from database and
  /// new messages coming live.
  List<ChatMessage> messages = [];

  /// list of event ids.
  List<String> eventIds = [];

  /// list of events.
  List<CalendarEvent> events = [];

  /// user ids mapped with appuser objects.
  HashMap<String, AppUser> users = HashMap();

  /// whether to censor chat messages. censors english bad words and images
  /// containing nudity.
  bool censoring = false;

  /// create chat room from home from mongo document. includes room id, name,
  /// image url, last message and app user object of sender of last message.
  ChatRoom.fromHomeJson(Map<String, dynamic> json) {
    _roomId = json['chatRoomId'];
    name = json['name'];
    imgUrl = json['imgUrl'];
    messages.add(ChatMessage(
      id: json['messageId'],
      msg: json['message'],
      roomId: _roomId,
      type: json['type'],
      userId: json['postedByUser']['_id'],
      dateTime: DateTime.parse(json['createdAt']).toLocal(),
    ));
    users[json['postedByUser']['_id']] = AppUser.fromJson(json['postedByUser']);
  }

  /// create chat room from mongo document during search.
  ChatRoom.fromSearchJson(Map<String, dynamic> json) {
    _roomId = json['_id'];
    name = json['name'];
    imgUrl = json['imgUrl'];
  }

  /// create chat room from mongo document, includes all messages in this room,
  /// and app user details of all users.
  ChatRoom.fromJsonWithMessages(Map<String, dynamic> json) {
    name = json['room']['name'];
    _roomId = json['room']['_id'];
    imgUrl = json['room']['imgUrl'];
    censoring = json['room']['censoring'];
    for (var item in json['conversation'])
      messages.add(ChatMessage.fromJson(item));

    for (var item in json['users']) users[item['_id']] = AppUser.fromJson(item);

    for (String item in json['room']['events']) eventIds.add(item);
  }

  /// create room just from room id, used when creating new chat room.
  ChatRoom({required roomId}) {
    this._roomId = roomId;
  }

  /// get unique room id.
  String get roomId => _roomId;

  // Widget _makeIcon() {
  //   return CircleAvatar(
  //     backgroundColor: Colors.white,
  //     backgroundImage: imgUrl == null || imgUrl!.isEmpty
  //         ? ExactAssetImage("DEFAULT_GROUP_IMG")
  //         : ImageDatabaseService.getImageByImageId(imgUrl!) as ImageProvider,
  //   );
  // }

  // Positioned editImageButton() {
  //   return Positioned(
  //       bottom: 0,
  //       right: 0,
  //       height: 30,
  //       width: 30,
  //       child: PopupMenuButton(
  //         onSelected: (choice) async {
  //           switch (choice) {
  //             case 'Edit':
  //               // _image = null;
  //               // await getImage();
  //               // if (_image != null) {
  //               //   var res = await editImage();
  //               //   if (res.statusCode == 200) setState(() {});
  //               // }
  //               break;

  //             case 'Remove':
  //               // var res = await removeImage();
  //               // if (res.statusCode == 200) setState(() {});
  //               break;
  //           }
  //         },
  //         icon: Icon(Icons.edit),
  //         itemBuilder: (context) => ['Edit', 'Remove']
  //             .map(
  //                 (choice) => PopupMenuItem(child: Text(choice), value: choice))
  //             .toList(),
  //       ));}
}
