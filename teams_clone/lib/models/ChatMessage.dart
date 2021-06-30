import 'package:teams_clone/models/AppUser.dart';

/// Represents a message of all types
class ChatMessage {
  /// Unique message id.
  late String _id;

  /// actual content of message, contains message string if type is text,
  /// unique image id if type is image, file name if type is file, and
  /// json if type is location.
  late String _msg;

  /// id of user who sent that message.
  late String _userId;

  /// id of room where message is sent.
  late String _roomId;

  /// message type: "text", "image", "file", "location".
  late String _type;

  /// date and time when message was sent.
  late DateTime _dateTime;

  /// app user who sent that message, can be null if not required in
  /// context.
  AppUser? _appUser;

  /// make a message in chat in chat room from socket json or mongo document.
  ChatMessage.fromJson(Map<String, dynamic> json) {
    _id = json['_id'];
    _msg = json['message'];
    _userId = json['postedByUser'];
    _roomId = json['chatRoomId'];
    _type = json['type'];
    _dateTime = DateTime.parse(json['createdAt']).toLocal();
  }

  /// make a message in search.
  ChatMessage.fromSearchJson(Map<String, dynamic> json) {
    _id = json['_id'];
    _msg = json['message'];
    _userId = json['postedByUser']['_id'];
    _appUser = AppUser.fromJson(json['postedByUser']);
    _roomId = json['chatRoomId'];
    _type = json['type'];
    _dateTime = DateTime.parse(json['createdAt']).toLocal();
  }

  /// use when making last message from home.
  ChatMessage(
      {required id,
      required msg,
      required userId,
      required roomId,
      required type,
      required dateTime}) {
    this._id = id;
    this._msg = msg;
    this._userId = userId;
    this._roomId = roomId;
    this._type = type;
    this._dateTime = dateTime;
  }

  /// get unique message id.
  String get id => _id;

  /// get actual content of message, contains message string if type is text,
  /// unique image id if type is image, file name if type is file, and
  /// json if type is location.
  String get msg => _msg;

  /// get id of user who sent that message.
  String get userId => _userId;

  /// get id of room where message is sent.
  String get roomId => _roomId;

  /// get message type: "text", "image", "file", "location".
  String get type => _type;

  /// get date and time when message was sent.
  DateTime get dateTime => _dateTime;

  /// get app user who sent that message, can be null if not required in
  /// context.
  AppUser? get appUser => _appUser;
}
