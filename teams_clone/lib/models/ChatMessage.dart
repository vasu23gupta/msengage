class ChatMessage {
  late String id;
  late String msg;
  late String userId;
  late String roomId;
  late String type;
  late DateTime dateTime;

  ChatMessage.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    msg = json['message'];
    userId = json['postedByUser'];
    roomId = json['chatRoomId'];
    type = json['type'];
    dateTime = DateTime.parse(json['createdAt']).toLocal();
  }

  ChatMessage({
    required this.id,
    required this.msg,
    required this.userId,
    required this.roomId,
    required this.type,
    required this.dateTime,
  });
}
