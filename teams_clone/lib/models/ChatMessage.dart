class ChatMessage {
  late String id;
  late String msg;
  late String userId;
  late String roomId;
  late bool isMedia;

  ChatMessage.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    msg = json['message'];
    userId = json['postedByUser'];
    roomId = json['chatRoomId'];
    isMedia = json['isMedia'];
  }
}
