import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:teams_clone/models/CalendarEvent.dart';
import 'package:teams_clone/models/ChatMessage.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:latlong2/latlong.dart';

/// URL of server.
const String URL = "http://10.0.2.2:3000/";
//const String URL = "https://teams-clone-by-vasu.herokuapp.com/";

/// To handle all formdata and query parameters related calls.
Dio _dio = Dio();

/// For all User related database functions.
class UserDBService {
  /// Route for users APIs.
  static String _usersUrl = URL + "users/";

  /// Store user information when signing up.
  static Future<http.Response> addUser(
      String username, String email, String uid) async {
    var body = jsonEncode({'username': username, 'email': email});
    final response = await http.post(Uri.parse(_usersUrl),
        headers: {'content-type': 'application/json', 'authorisation': uid},
        body: body);
    return response;
  }

  /// Returns unique user id of user from their email id.
  static Future<String?> getUserIdFromEmail(String email) async {
    http.Response res = await http.get(Uri.parse(_usersUrl + email));
    var body = jsonDecode(res.body);
    return body == null ? null : body['_id'];
  }

  /// To change user's profile picture. Returns image id of uploaded image.
  static Future<String> changeUserIcon(User user, String path) async {
    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(path),
      'old': user.photoURL,
    });

    Response res = await _dio.patch(
      _usersUrl + "changeIcon/" + user.uid,
      data: formData,
    );
    return res.data['imgUrl'];
  }

  /// To remove user's profile picture.
  static Future<bool> removeUserIcon(User user) async {
    var body = jsonEncode({'old': user.photoURL});
    http.Response res = await http.patch(
      Uri.parse(_usersUrl + "removeIcon/" + user.uid),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (res.statusCode == 200) user.updatePhotoURL(null);
    return res.statusCode == 200;
  }

  /// To search for chat rooms a user is in, events a user has, and messages
  /// sent or received by user. Make sure [query] is trimmed.
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

/// For all chat related database functions.
class ChatDatabaseService {
  /// Route for chats APIs.
  static String _chatUrl = URL + "chat/";

  /// Returns list of chat rooms the user is in. Chat rooms include name, imgurl, id of
  /// chat room and last chat message and the app user sender of that message.
  static Future<List<ChatRoom>> getChatRooms(String uid) async {
    http.Response res =
        await http.get(Uri.parse(_chatUrl), headers: {'authorisation': uid});
    var body = jsonDecode(res.body);
    List<ChatRoom> _rooms = [];
    for (var json in body['conversation'])
      _rooms.add(ChatRoom.fromHomeJson(json));
    return _rooms;
  }

  /// Add users in a chat room. Returns true if all users were added, false
  /// otherwise.
  static Future<bool> addUsersToChatRoom(
      String roomId, List<String> userIds) async {
    var body = jsonEncode({'users': userIds});

    http.Response res = await http.patch(
      Uri.parse(_chatUrl + "room/addUsers/" + roomId),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    return res.statusCode == 200;
  }

  /// Create a new chat room. [ids] is list of user ids of participants,
  /// [room] has to contain the name and image of the chat room, [uid] is user
  /// id of creator of chat room. Returns room id of newly created room if new
  /// room is created or a room with same participants and name exists,
  /// null otherwise.
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

  /// Returns a complete chat room with id [roomId] .
  static Future<ChatRoom> getChatRoomByRoomId(String roomId) async {
    http.Response res = await http.get(Uri.parse(_chatUrl + "room/" + roomId));
    ChatRoom cr = ChatRoom.fromJsonWithMessages(jsonDecode(res.body));
    return cr;
  }

  /// Sends a message [msg] with type [type] to the room with id [roomId].
  static Future<bool> sendMessage(
      String msg, String roomId, String uid, String type) async {
    var body = jsonEncode({'messageText': msg, 'type': type});
    http.Response res = await http.post(
        Uri.parse(_chatUrl + "room/message/" + roomId),
        headers: {'authorisation': uid, 'Content-Type': 'application/json'},
        body: body);
    return res.statusCode == 200;
  }

  /// Leaves the chat room with id [roomId]. Returns true if left successfully,
  /// false otherwise.
  static Future<bool> leaveChatRoom(String roomId, String uid) async {
    http.Response res = await http.patch(
      Uri.parse(_chatUrl + "room/leave/" + roomId),
      headers: {'authorisation': uid},
    );
    return res.statusCode == 200;
  }

  /// Changes name of chat room with id [roomId]. Returns true if changed
  /// successfully, false otherwise.
  static Future<bool> changeRoomName(
      String roomId, String uid, String name) async {
    http.Response res = await http.patch(
        Uri.parse(_chatUrl + "room/changeRoomName/" + roomId),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}));

    return res.statusCode == 200;
  }

  /// Updates the icon of chat room [room] with [path] being the path of
  /// new image. Returns id of new image.
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

  /// Removes the icon of chat room [room]. Returns true if removed
  /// successfully, false otherwise.
  static Future<bool> removeRoomIcon(ChatRoom room) async {
    var body = jsonEncode({'old': room.imgUrl});
    http.Response res = await http.patch(
      Uri.parse(_chatUrl + "room/removeRoomIcon/" + room.roomId),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    return res.statusCode == 200;
  }

  /// Changes the censorship rule of chat room with id [roomId]. Returns true
  /// if changed successfully, false otherwise.
  static Future<bool> changeRoomCensorship(
      String roomId, String uid, bool censoring) async {
    http.Response res = await http.patch(
        Uri.parse(_chatUrl + "room/changeRoomCensorship/" + roomId),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'censoring': censoring}));

    return res.statusCode == 200;
  }
}

/// For all events related database functions.
class CalendarDatabaseService {
  /// Route for events APIs.
  static String _eventsUrl = URL + "events/";

  /// Creates a new event with [start] as the starting date time, [end] as
  /// ending date time, [title] as title of event and [roomId] as id of room
  /// where the event is being created. Leave [roomId] empty if it is a
  /// personal event. Returns the newly created event.
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

  /// Returns the [CalendarEvent] object of the given [eventId].
  static Future<CalendarEvent> getEventFromEventId(String eventId) async {
    http.Response res = await http.get(Uri.parse(_eventsUrl + eventId));
    return CalendarEvent.fromJson(jsonDecode(res.body));
  }

  /// Returns list of all [CalendarEvent]s a user has including personal and
  /// group events.
  static Future<List<CalendarEvent>> getEventFromUserId(String uid) async {
    http.Response res = await http.get(Uri.parse(_eventsUrl + "user/" + uid));
    List<CalendarEvent> result = [];
    var body = jsonDecode(res.body);
    for (var item in body) result.add(CalendarEvent.fromJson(item));
    return result;
  }

  /// Deletes a event with id [eventId]. Returns true if deleted successfully,
  /// false otherwise.
  static Future<bool> deleteEventFromEventId(String eventId) async {
    http.Response res = await http.delete(Uri.parse(_eventsUrl + eventId));
    return res.statusCode == 200;
  }
}

/// For all images related database functions.
class ImageDatabaseService {
  /// Route for images APIs.
  static String _imagesUrl = URL + "images/";

  /// Returns a [CachedNetworkImageProvider] object of a given image id [id].
  static CachedNetworkImageProvider getImageByImageId(String id) =>
      CachedNetworkImageProvider(_imagesUrl + id);

  /// Uploads image with path [path]. [filter] has to be true if you don't
  /// want the image to be saved if it contains nudity.
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

/// Returns a json containing various information about the coordinates
/// [coords] including country, state, city etc.
Future<Map<String, dynamic>> reverseGeocode(LatLng coords) async {
  String _revGeoApiKey = "pk.2f59bc5282019634c04ee4b55f7e9798";
  String _revGeoUrl = "https://eu1.locationiq.com/v1/reverse.php";
  Map<String, dynamic> queryParams = {
    'key': _revGeoApiKey,
    'lat': coords.latitude,
    'lon': coords.longitude,
    'format': 'json'
  };
  Response res = await _dio.get(_revGeoUrl, queryParameters: queryParams);
  Map<String, dynamic> result = {
    'place': res.data['display_name'],
    'lat': coords.latitude,
    'lon': coords.longitude
  };
  return result;
}
