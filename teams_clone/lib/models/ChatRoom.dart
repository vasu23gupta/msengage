import 'package:teams_clone/models/ChatMessage.dart';

class ChatRoom {
  late String roomId;
  late String name;
  String? imgUrl;
  List<ChatMessage> messages = [];

  ChatRoom.fromHomeJson(Map<String, dynamic> json) {
    roomId = json['_id'];
    name = json['name'];
    imgUrl = json['imgUrl'];
  }

  ChatRoom.fromJsonWithMessages(Map<String, dynamic> json) {
    name = json['room']['name'];
    roomId = json['room']['_id'];
    imgUrl = json['room']['imgUrl'];
    for (var item in json['conversation']) {
      messages.add(ChatMessage.fromJson(item));
    }
  }

  ChatRoom({required this.roomId});
}
