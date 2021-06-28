import 'dart:collection';
import 'package:teams_clone/models/AppUser.dart';
import 'package:teams_clone/models/CalendarEvent.dart';
import 'package:teams_clone/models/ChatMessage.dart';

class ChatRoom {
  late String roomId;
  late String name;
  String? imgUrl;
  List<ChatMessage> messages = [];
  List<String> eventIds = [];
  List<CalendarEvent> events = [];
  HashMap<String, AppUser> users = HashMap();
  bool censoring = false;

  ChatRoom.fromHomeJson(Map<String, dynamic> json) {
    roomId = json['chatRoomId'];
    name = json['name'];
    imgUrl = json['imgUrl'];
    messages.add(ChatMessage(
        id: json['messageId'],
        msg: json['message'],
        roomId: roomId,
        type: json['type'],
        userId: json['postedByUser']['_id'],
        dateTime: DateTime.parse(json['createdAt']).toLocal()));
    users[json['postedByUser']['_id']] = AppUser.fromJson(json['postedByUser']);
  }

  ChatRoom.fromSearchJson(Map<String, dynamic> json) {
    roomId = json['_id'];
    name = json['name'];
    imgUrl = json['imgUrl'];
  }

  ChatRoom.fromJsonWithMessages(Map<String, dynamic> json) {
    name = json['room']['name'];
    roomId = json['room']['_id'];
    imgUrl = json['room']['imgUrl'];
    censoring = json['room']['censoring'];
    for (var item in json['conversation'])
      messages.add(ChatMessage.fromJson(item));

    for (var item in json['users']) users[item['_id']] = AppUser.fromJson(item);

    for (String item in json['room']['events']) eventIds.add(item);
  }

  ChatRoom({required this.roomId});

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
