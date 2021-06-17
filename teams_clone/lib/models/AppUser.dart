import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppUser {
  late String name;
  late String id;
  String? imgUrl;
  late CircleAvatar icon;

  AppUser.fromJson(Map<String, dynamic> json) {
    name = json['username'];
    id = json['_id'];
    imgUrl = json['imgUrl'];
    if (imgUrl == null || imgUrl!.isEmpty)
      icon = CircleAvatar(child: Text(name.substring(0, 2).toUpperCase()));
    else
      icon = CircleAvatar(backgroundImage: NetworkImage(imgUrl!));
  }
}
