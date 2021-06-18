import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:teams_clone/models/ChatRoom.dart';

const String URL = "http://10.0.2.2:3000/";

class UserDBService {
  static String _usersUrl = URL + "users/";

  static Future<http.Response> addUser(
      String username, String email, String uid) async {
    var body = jsonEncode({'username': username, 'email': email});
    final response = await http.post(Uri.parse(_usersUrl),
        headers: {'content-type': 'application/json', 'authorisation': uid},
        body: body);
    return response;
  }

  static Future<String?> getUserIdFromEmail(String email) async {
    http.Response res = await http.get(Uri.parse(_usersUrl + email));
    var body = jsonDecode(res.body);
    return body == null ? null : body['_id'];
  }
}

class ChatDatabaseService {
  static String _chatUrl = URL + "chat/";

  static Future<http.Response> getChatRooms(String uid) async {
    http.Response res =
        await http.get(Uri.parse(_chatUrl), headers: {'authorisation': uid});
    return res;
  }

  static Future<String?> createNewChatRoom(
      List<String> ids, String name, String uid) async {
    var body = jsonEncode({'name': name, 'userIds': ids});
    http.Response res = await http.post(
      Uri.parse(_chatUrl + "initiate/"),
      body: body,
      headers: {'authorisation': uid, 'Content-Type': 'application/json'},
    );
    var resBody = jsonDecode(res.body);
    return resBody['success'] == 'false'
        ? null
        : resBody['chatRoom']['chatRoomId'];
  }

  static Future<ChatRoom> getChatRoomByRoomId(String roomId) async {
    http.Response res = await http.get(Uri.parse(_chatUrl + "room/" + roomId));
    ChatRoom cr = ChatRoom.fromJsonWithMessages(jsonDecode(res.body));
    return cr;
  }

  static Future sendMessage(
      String msg, String roomId, String uid, bool isMedia) async {
    var body = jsonEncode({'messageText': msg, 'isMedia': isMedia});
    http.Response res = await http.post(
        Uri.parse(_chatUrl + "room/message/" + roomId),
        headers: {'authorisation': uid, 'Content-Type': 'application/json'},
        body: body);
    return res;
  }

  static Future<bool> leaveChatRoom(String roomId, String uid) async {
    http.Response res = await http.patch(
      Uri.parse(_chatUrl + "room/leave/" + roomId),
      headers: {'authorisation': uid},
    );
    if (res.statusCode == 200) return true;
    return false;
  }

  static Future<bool> changeRoomName(
      String roomId, String uid, String name) async {
    http.Response res = await http.patch(
        Uri.parse(_chatUrl + "room/changeRoomName/" + roomId),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}));
    if (res.statusCode == 200) return true;
    return false;
  }

  static Future<bool> changeRoomCensorship(
      String roomId, String uid, bool censoring) async {
    http.Response res = await http.patch(
        Uri.parse(_chatUrl + "room/changeRoomCensorship/" + roomId),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'censoring': censoring}));
    if (res.statusCode == 200) return true;
    return false;
  }
}
