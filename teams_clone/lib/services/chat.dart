import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:teams_clone/services/database.dart';

class StreamSocket {
  final _socketResponse = StreamController<dynamic>.broadcast();

  void Function(dynamic) get addResponse => _socketResponse.sink.add;

  Stream<dynamic> get getResponse => _socketResponse.stream;

  void dispose() {
    _socketResponse.close();
  }
}

StreamSocket streamSocket = StreamSocket();
Socket socket = io(URL, <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': true,
});

//STEP2: Add this function in main function in main.dart file and add incoming data to the stream
void connectAndListen(String uid) {
  socket.onConnect((_) {
    print('connected chat');
    socket.emit("identity", {"userId": uid});
  });

  socket.onConnectError((data) => print("onConnectError: " + data.toString()));

  socket.onConnectTimeout(
      (data) => print("onConnectTimeout: " + data.toString()));

  socket.onError((data) => print("onError: " + data.toString()));

  socket.on("new message", (data) {
    print("[message]: $data");
    streamSocket.addResponse(data);
  });

  socket.on('event', (data) => streamSocket.addResponse);

  socket.onDisconnect((_) => print('disconnect'));
}
