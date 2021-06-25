import 'dart:convert';

class ScriptCallback {
  String? method;
  String? body;
  String? error;

  ScriptCallback(String method, String body, String error) {
    this.method = method;
    this.body = body;
    this.error = error;
  }

  @override
  String toString() {
    return "Method: $method, body: $body, error: $error";
  }
}

class CommandCallback {
  Map<String, dynamic>? data;

  CommandCallback(String payload) {
    data = jsonDecode(payload);
  }

  @override
  String toString() {
    return data.toString();
  }
}

class EventCallback {
  String? name;
  Map<String, dynamic>? data;

  EventCallback(String event, String payload) {
    name = event;
    data = jsonDecode(payload);
  }

  @override
  String toString() {
    return data.toString();
  }
}

class ButtonStateCallback {
  String? stateName;

  ButtonStateCallback(String newState) {
    stateName = newState;
  }
}

class Command {
  Map<String, dynamic>? data;

  Command(String payload) {
    data = jsonDecode(payload);
  }

  @override
  String toString() {
    return data.toString();
  }
}

class Event {
  Map<String, dynamic>? data;

  Event(String payload) {
    data = jsonDecode(payload);
  }

  @override
  String toString() {
    return data.toString();
  }
}

class ButtonState {
  String? name;

  ButtonState(String state) {
    name = state;
  }
}
