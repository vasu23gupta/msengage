import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppUser {
  late String name;
  late String id;
  late String email;
  String? imgUrl;
  late CircleAvatar icon;

  AppUser.fromJson(Map<String, dynamic> json) {
    name = json['username'];
    id = json['_id'];
    imgUrl = json['imgUrl'];
    email = json['email'];
    if (imgUrl == null || imgUrl!.isEmpty)
      icon = CircleAvatar(child: Text(name.substring(0, 2).toUpperCase()));
    else
      icon = CircleAvatar(backgroundImage: NetworkImage(imgUrl!));
  }

  AppUser.fromFirebaseUser(User user) {
    name = user.displayName!;
    id = user.uid;
    imgUrl = user.photoURL;
    email = user.email!;
    if (imgUrl == null || imgUrl!.isEmpty)
      icon = CircleAvatar(child: Text(name.substring(0, 2).toUpperCase()));
    else
      icon = CircleAvatar(backgroundImage: NetworkImage(imgUrl!));
  }
}
