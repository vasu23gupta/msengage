import 'package:flutter/material.dart';
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
  List<AppUser> users = [];
  late CircleAvatar icon;
  bool censoring = false;

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
    censoring = json['room']['censoring'];
    for (var item in json['conversation'])
      messages.add(ChatMessage.fromJson(item));

    for (var item in json['users']) users.add(AppUser.fromJson(item));

    for (String item in json['room']['events']) eventIds.add(item);
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
