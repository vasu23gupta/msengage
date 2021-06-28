import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  late String name;
  late String id;
  late String email;
  String? imgUrl;

  AppUser.fromJson(Map<String, dynamic> json) {
    name = json['username'];
    id = json['_id'];
    imgUrl = json['imgUrl'];
    email = json['email'];
  }

  AppUser.fromFirebaseUser(User user) {
    name = user.displayName == null
        ? user.email!.split('@')[0]
        : user.displayName!;
    id = user.uid;
    imgUrl = user.photoURL;
    email = user.email!;
  }
}
