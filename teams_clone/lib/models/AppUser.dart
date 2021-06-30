import 'package:firebase_auth/firebase_auth.dart';

/// Encapsulates both, first and third person and
/// provides easy access to details.
class AppUser {
  /// username of user
  late String _name;

  /// user id of user
  late String _id;

  /// email id of user
  late String _email;

  /// url of profile picture. can be null if user doesnt
  /// have a profile picture.
  String? imgUrl;

  ///make app user from mongo document
  AppUser.fromJson(Map<String, dynamic> json) {
    _name = json['username'];
    _id = json['_id'];
    imgUrl = json['imgUrl'];
    _email = json['email'];
  }

  /// To make first person user from firebase user.
  AppUser.fromFirebaseUser(User user) {
    _name = user.displayName == null
        ? user.email!.split('@')[0]
        : user.displayName!;
    _id = user.uid;
    imgUrl = user.photoURL;
    _email = user.email!;
  }

  /// Get the name of the user.
  String get name => _name;

  /// Get the id of the user.
  String get id => _id;

  /// Get the email of the user.
  String get email => _email;
}
