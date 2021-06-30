import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:teams_clone/services/database.dart';

/// Stream manager for chat front end.
class StreamSocket {
  final _socketResponse = StreamController<dynamic>.broadcast();

  void Function(dynamic) get addResponse => _socketResponse.sink.add;

  Stream<dynamic> get getResponse => _socketResponse.stream;

  void dispose() => _socketResponse.close();
}

/// Stream manager for chat front end.
StreamSocket streamSocket = StreamSocket();

/// Socket object to communicate with other clients.
Socket socket = io(URL, <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': true,
});

/// Connects [Socket] socket and [StreamSocket] stream manager.
void connectAndListen() {
  socket.onConnect((_) => print('connected chat'));

  socket.onConnectError((data) => print("onConnectError: " + data.toString()));

  socket.onConnectTimeout(
      (data) => print("onConnectTimeout: " + data.toString()));

  socket.onError((data) => print("onError: " + data.toString()));

  socket.on("new message", (data) => streamSocket.addResponse(data));

  socket.on('event', (data) => streamSocket.addResponse);

  socket.onDisconnect((_) => print('disconnect'));
}
