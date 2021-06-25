import 'dart:async';

import 'package:flutter/services.dart';
import 'alan_callback.dart';

typedef void OnCommandCallback(Command command);
typedef void OnButtonStateCallback(ButtonState state);
typedef void OnEventCallback(Event payload);

@deprecated
typedef void CommandCallbackFunction(CommandCallback command);
@deprecated
typedef void ButtonStateCallbackFunction(ButtonStateCallback state);
@deprecated
typedef void EventCallbackFunction(EventCallback event);
@deprecated
typedef void ConnectionStateCallback(String newState);

class AlanVoice {
  static const String PLUGIN_VERSION = "2.3.0";

  static const MethodChannel _channel = const MethodChannel('alan_voice');
  static const EventChannel _callBackChannel =
      const EventChannel('alan_voice_callback');

  static const BUTTON_ALIGN_LEFT = 1;
  static const BUTTON_ALIGN_RIGHT = 2;

  static Set<OnCommandCallback> onCommand = Set();
  static Set<OnEventCallback> onEvent = Set();
  static Set<OnButtonStateCallback> onButtonState = Set();

  // ignore: deprecated_member_use_from_same_package
  static Set<CommandCallbackFunction> callbacks = Set();
  // ignore: deprecated_member_use_from_same_package
  static Set<EventCallbackFunction> eventCallbacks = Set();
  // ignore: deprecated_member_use_from_same_package
  static Set<ButtonStateCallbackFunction> buttonStateCallbacks = Set();
  // ignore: deprecated_member_use_from_same_package
  static Set<ConnectionStateCallback> _connectionCallbacks = Set();

  static void init() {
    _channel.setMethodCallHandler((MethodCall call) async {
      return true;
    });
  }

  @deprecated
  static void _handleEvent(String event, String payload) {
    eventCallbacks.forEach((e) => e(EventCallback(event, payload)));
  }

  @deprecated
  static void _handleButtonState(String newState) {
    buttonStateCallbacks.forEach((e) => e(ButtonStateCallback(newState)));
  }

  @deprecated
  static void _handleCommand(String payload) {
    callbacks.forEach((e) => e(CommandCallback(payload)));
  }

  static void _onEvent(String payload) {
    onEvent.forEach((e) => e(Event(payload)));
  }

  static void _onButtonState(String newState) {
    onButtonState.forEach((e) => e(ButtonState(newState)));
  }

  static void _onCommand(String payload) {
    callbacks.forEach((e) => e(CommandCallback(payload)));
    onCommand.forEach((e) => e(Command(payload)));
  }

  ///
  /// Print Alan SDK version info
  ///
  static Future<String> get version async {
    String version = await _channel.invokeMethod('getVersion');
    version = "Plugin version: $PLUGIN_VERSION\n$version";
    return version;
  }

  ///
  /// Show Alan button
  ///
  static void showButton() async {
    await _channel.invokeMethod('showButton');
  }

  ///
  /// Hide Alan button
  ///
  static void hideButton() async {
    await _channel.invokeMethod('hideButton');
  }

  ///
  /// Returns true if Alan Button is Active
  /// (activated by `activate` method or pressed by user)
  /// False otherwise
  ///
  static Future<bool> isActive() async {
    return await _channel.invokeMethod('isActive');
  }

  ///
  /// Remove Alan button
  ///
  static void removeButton() async {
    await _channel.invokeMethod('removeButton');
  }

  ///
  /// Set AlanSDK log level
  ///
  /// arguments:
  ///   logLevel - "all", "none"
  ///
  static void setLogLevel(String logLevel) async {
    try {
      await _channel
          .invokeMethod('setLogLevel', <String, dynamic>{"logLevel": logLevel});
    } catch (e) {
      print("Failed to set log level $e");
    }
  }

  ///
  /// Inits SDK, connect to the script side and show Alan button
  ///
  /// arguments:
  ///   projectId - projectId as written in `embed code` section on the project page
  ///   authJson - initial variables formatted as json string
  ///
  static void addButton(String projectId,
      {String? authJson,
      String? server,
      int buttonAlign = BUTTON_ALIGN_RIGHT,
      int topMargin = 0,
      int bottomMargin = 20}) async {
    try {
      await _channel.invokeMethod('addButton', <String, dynamic>{
        "projectId": projectId,
        "projectServer": server,
        "projectAuthJson": authJson,
        "buttonAlign": buttonAlign,
        "topMargin": topMargin,
        "bottomMargin": bottomMargin,
        "wrapperVersion": PLUGIN_VERSION
      });
    } catch (e) {
      print("Failed to add Alan button $e");
    }

    _callBackChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is List) {
        var method = event[0] as String;
        switch (method) {
          case "button_state_changed":
            // ignore: deprecated_member_use_from_same_package
            _handleButtonState(event[1]);
            break;
          case "command":
            // ignore: deprecated_member_use_from_same_package
            _handleCommand(event[1]);
            break;
          case "event":
            // ignore: deprecated_member_use_from_same_package
            _handleEvent(event[1], event[2]);
            break;
          case "onEvent":
            _onEvent(event[1]);
            break;
          case "onButtonState":
            _onButtonState(event[1]);
            break;
          case "onCommand":
            _onCommand(event[1]);
            break;
          default:
            print("Unknown event type $method");
        }
      } else {
        print("Event is not a list, but $event");
      }
    }, onError: (dynamic error) {
      print("Got error in callbacks: $error");
    });
  }

  ///
  /// Call script function by name
  /// arguments:
  ///   method - script side method name
  ///   args - arguments serialized to a json string
  static void playText(String text) async {
    _channel.invokeMethod('playText', <String, String>{"text": text});
  }

  ///
  /// Activate Alan button
  ///
  static void activate() async {
    _channel.invokeMethod('activate');
  }

  ///
  /// Deactivate Alan button
  ///
  static void deactivate() async {
    _channel.invokeMethod('deactivate');
  }

  ///
  /// Sends command to a script
  /// arguments:
  ///   command - command name
  ///
  static Future<ScriptCallback> playCommand(String command) async {
    List<dynamic> result = await _channel
        .invokeMethod('playCommand', <String, String>{"command": command});

    return ScriptCallback(
        result[0].toString(), result[1].toString(), result[2].toString());
  }

  ///
  /// Call script function by name
  /// arguments:
  ///   method - script side method name
  ///   args - arguments serialized to a json string
  ///
  static Future<ScriptCallback> callProjectApi(
      String method, String args) async {
    List<dynamic> result = await _channel.invokeMethod('callProjectApi',
        <String, String>{"method_name": method, "method_args": args});

    return ScriptCallback(
        result[0].toString(), result[1].toString(), result[2].toString());
  }

  ///
  /// Set script visuals.
  /// visuals argument should be a valid json
  ///
  static void setVisualState(String visuals) async {
    try {
      _channel
          .invokeMethod('setVisualState', <String, String>{"visuals": visuals});
    } catch (e) {
      print("Set visual state failed with: $e");
    }
  }

  @deprecated
  static void addConnectionCallback(
      ConnectionStateCallback connectionCallback) {
    _connectionCallbacks.add(connectionCallback);
  }

  @deprecated
  static void removeConnectionCallback(
      ConnectionStateCallback connectionCallback) {
    _connectionCallbacks.remove(connectionCallback);
  }

  static void clearCallbacks() {
    _connectionCallbacks.clear();
    buttonStateCallbacks.clear();
    eventCallbacks.clear();
    callbacks.clear();
    onButtonState.clear();
    onCommand.clear();
    onEvent.clear();
  }
}
