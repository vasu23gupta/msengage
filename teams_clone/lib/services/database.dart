import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:teams_clone/models/AppUser.dart';
import 'package:teams_clone/models/CalendarEvent.dart';
import 'package:teams_clone/models/ChatMessage.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:latlong2/latlong.dart';

const String URL = "http://10.0.2.2:3000/";

class UserDBService {
  static String _usersUrl = URL + "users/";
  static Dio _dio = Dio();

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

  static Future<String> changeUserIcon(
      User user, AppUser appUser, String path) async {
    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(path),
      'old': appUser.imgUrl,
    });

    Response res = await _dio.patch(
      _usersUrl + "changeIcon/" + appUser.id,
      data: formData,
    );
    if (res.statusCode == 200) user.updatePhotoURL(res.data['imgUrl']);
    return res.data['imgUrl'];
  }

  static Future<bool> removeUserIcon(User user, AppUser appUser) async {
    var body = jsonEncode({'old': appUser.imgUrl});
    http.Response res = await http.patch(
      Uri.parse(_usersUrl + "removeIcon/" + appUser.id),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (res.statusCode == 200) user.updatePhotoURL(null);
    return res.statusCode == 200;
  }

  static Future<Map<String, dynamic>> search(String query, String uid) async {
    http.Response res = await http.get(Uri.parse(_usersUrl + "search/" + query),
        headers: {'authorisation': uid});
    Map<String, dynamic> result = {};
    result['rooms'] = <ChatRoom>[];
    result['events'] = <CalendarEvent>[];
    result['messages'] = <ChatMessage>[];
    var json = jsonDecode(res.body);
    for (var room in json['rooms'])
      result['rooms'].add(ChatRoom.fromSearchJson(room));

    for (var event in json['events'])
      result['events'].add(CalendarEvent.fromJson(event));

    for (var msg in json['messages'])
      result['messages'].add(ChatMessage.fromSearchJson(msg));

    return result;
  }
}

class ChatDatabaseService {
  static String _chatUrl = URL + "chat/";
  static Dio _dio = Dio();

  static Future<List<ChatRoom>> getChatRooms(String uid) async {
    http.Response res =
        await http.get(Uri.parse(_chatUrl), headers: {'authorisation': uid});
    var body = jsonDecode(res.body);
    List<ChatRoom> _rooms = [];
    for (var json in body['conversation'])
      _rooms.add(ChatRoom.fromHomeJson(json));
    return _rooms;
  }

  static Future<bool> addUsersToChatRoom(
      String roomId, List<String> users) async {
    var body = jsonEncode({'users': users});
    http.Response res = await http.patch(
      Uri.parse(_chatUrl + "room/addUsers/" + roomId),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    return res.statusCode == 200;
  }

  static Future<String?> createNewChatRoom(
      List<String> ids, ChatRoom room, String uid) async {
    FormData formData = FormData.fromMap({
      'chatInitiator': uid,
      'name': room.name,
      'userIds': ids,
      'image':
          room.imgUrl == null ? "" : await MultipartFile.fromFile(room.imgUrl!),
    });
    Response res = await _dio.post(_chatUrl + "initiate/", data: formData);
    var resBody = res.data;
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
      String msg, String roomId, String uid, String type) async {
    var body = jsonEncode({'messageText': msg, 'type': type});
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

  static Future<String> changeRoomIcon(ChatRoom room, String path) async {
    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(path),
      'old': room.imgUrl,
    });

    Response res = await _dio.patch(
      _chatUrl + "room/changeRoomIcon/" + room.roomId,
      data: formData,
    );

    return res.data['imgUrl'];
  }

  static Future<bool> removeRoomIcon(ChatRoom room) async {
    var body = jsonEncode({'old': room.imgUrl});
    http.Response res = await http.patch(
      Uri.parse(_chatUrl + "room/removeRoomIcon/" + room.roomId),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    return res.statusCode == 200;
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

class CalendarDatabaseService {
  static String _eventsUrl = URL + "events/";

  static Future<CalendarEvent> createEvent(DateTime start, DateTime end,
      String title, String uid, String roomId) async {
    var body = jsonEncode({
      'title': title,
      'startTime': start.toString(),
      'endTime': end.toString(),
      'createdBy': uid,
      'roomId': roomId
    });
    http.Response res = await http.post(
      Uri.parse(_eventsUrl),
      body: body,
      headers: {'Content-Type': 'application/json'},
    );
    return CalendarEvent.fromJson(jsonDecode(res.body));
  }

  static Future<CalendarEvent> getEventFromEventId(String eventId) async {
    http.Response res = await http.get(Uri.parse(_eventsUrl + eventId));
    return CalendarEvent.fromJson(jsonDecode(res.body));
  }

  static Future<List<CalendarEvent>> getEventFromUserId(String uid) async {
    http.Response res = await http.get(Uri.parse(_eventsUrl + "user/" + uid));
    List<CalendarEvent> result = [];
    var body = jsonDecode(res.body);
    print(body);
    for (var item in body) result.add(CalendarEvent.fromJson(item));
    return result;
  }

  static Future<bool> deleteEventFromEventId(String eventId) async {
    http.Response res = await http.delete(Uri.parse(_eventsUrl + eventId));
    return res.statusCode == 200;
  }
}

class ImageDatabaseService {
  static String _imagesUrl = URL + "images/";
  static Dio _dio = Dio();

  static NetworkImage getImageByImageId(String id) {
    return NetworkImage(_imagesUrl + id);
  }

  static Future<String> uploadImage(String path, bool filter) async {
    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(path),
      'filter': filter,
    });

    Response res = await _dio.post(_imagesUrl, data: formData);
    String imgId;
    print(res.data);
    if (res.statusCode != 200)
      imgId = '';
    else
      imgId = res.data;

    return imgId;
  }
}

class Utils {
  static String _revGeoApiKey = "pk.2f59bc5282019634c04ee4b55f7e9798";
  static String _revGeoUrl = "https://eu1.locationiq.com/v1/reverse.php";

  static Future<Map<String, dynamic>> reverseGeocode(LatLng coords) async {
    Map<String, dynamic> queryParams = {
      'key': _revGeoApiKey,
      'lat': coords.latitude,
      'lon': coords.longitude,
      'format': 'json'
    };
    Response res = await Dio().get(_revGeoUrl, queryParameters: queryParams);
    Map<String, dynamic> result = {
      'place': res.data['display_name'],
      'lat': coords.latitude,
      'lon': coords.longitude
    };
    return result;
  }
}
