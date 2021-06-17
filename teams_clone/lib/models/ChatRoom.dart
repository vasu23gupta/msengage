import 'package:flutter/material.dart';
import 'package:teams_clone/models/AppUser.dart';
import 'package:teams_clone/models/ChatMessage.dart';

class ChatRoom {
  late String roomId;
  late String name;
  String? imgUrl;
  List<ChatMessage> messages = [];
  List<AppUser> users = [];
  late CircleAvatar icon;

  ChatRoom.fromHomeJson(Map<String, dynamic> json) {
    roomId = json['_id'];
    name = json['name'];
    imgUrl = json['imgUrl'];
    icon = _makeIcon();
  }

  ChatRoom.fromJsonWithMessages(Map<String, dynamic> json) {
    name = json['room']['name'];
    roomId = json['room']['_id'];
    imgUrl = json['room']['imgUrl'];
    for (var item in json['conversation'])
      messages.add(ChatMessage.fromJson(item));

    for (var item in json['users']) users.add(AppUser.fromJson(item));
    icon = _makeIcon();
  }

  ChatRoom({required this.roomId});
  CircleAvatar _makeIcon() {
    return CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage: imgUrl == null || imgUrl!.isEmpty
            ? ExactAssetImage("assets/default_group_icon.png")
            : NetworkImage(imgUrl!) as ImageProvider);
  }
}
