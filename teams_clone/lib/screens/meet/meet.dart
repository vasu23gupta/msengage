import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:provider/provider.dart';

class Meeting extends StatefulWidget {
  @override
  _MeetingState createState() => _MeetingState();
}

class _MeetingState extends State<Meeting> {
  final roomText = TextEditingController();
  late User? _user;

  @override
  void initState() {
    super.initState();
    JitsiMeet.addListener(JitsiMeetingListener(
        onConferenceWillJoin: _onConferenceWillJoin,
        onConferenceJoined: _onConferenceJoined,
        onConferenceTerminated: _onConferenceTerminated,
        onError: _onError));
    _user = Provider.of<User?>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
    JitsiMeet.removeAllListeners();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return MaterialApp(
      home: Scaffold(
        body: kIsWeb
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: width * 0.30,
                    child: meetConfig(),
                  ),
                  Container(
                      width: width * 0.60,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                            color: Colors.white54,
                            child: SizedBox(
                              width: width * 0.60 * 0.70,
                              height: width * 0.60 * 0.70,
                              child: JitsiMeetConferencing(
                                extraJS: [
                                  // extraJs setup example
                                  '<script>function echo(){console.log("echo!!!")};</script>',
                                  '<script src="https://code.jquery.com/jquery-3.5.1.slim.js" integrity="sha256-DrT5NfxfbHvMHux31Lkhxg42LY6of8TaYyK50jnxRnM=" crossorigin="anonymous"></script>'
                                ],
                              ),
                            )),
                      ))
                ],
              )
            : meetConfig(),
      ),
    );
  }

  Widget meetConfig() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          TextField(
            controller: roomText,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Enter organiser's username",
            ),
          ),
          ElevatedButton(
              onPressed: () => _joinMeeting(roomText.text),
              child: Text("Join Meeting")),
          Text("OR"),
          ElevatedButton(
              onPressed: () => _joinMeeting(_user!.email!.split('@')[0]),
              child: Text("Create Meeting")),
        ],
      ),
    );
  }

  _joinMeeting(String roomName) async {
    // Enable or disable any feature flag here
    // If feature flag are not provided, default values will be used
    Map<FeatureFlagEnum, bool> featureFlags = {
      FeatureFlagEnum.WELCOME_PAGE_ENABLED: false
    };
    if (!kIsWeb) {
      if (Platform.isAndroid)
        featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
      else if (Platform.isIOS)
        featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
    }
    // Define meetings options here
    var options = JitsiMeetingOptions(room: roomName)
      ..userDisplayName = _user!.displayName
      ..featureFlags.addAll(featureFlags)
      ..webOptions = {
        "roomName": roomName,
        "width": "100%",
        "height": "100%",
        "enableWelcomePage": false,
        "chromeExtensionBanner": null,
        "userInfo": {"displayName": _user!.displayName}
      };

    debugPrint("JitsiMeetingOptions: $options");
    await JitsiMeet.joinMeeting(
      options,
      listener: JitsiMeetingListener(
          onConferenceWillJoin: (message) =>
              debugPrint("${options.room} will join with message: $message"),
          onConferenceJoined: (message) =>
              debugPrint("${options.room} joined with message: $message"),
          onConferenceTerminated: (message) =>
              debugPrint("${options.room} terminated with message: $message"),
          genericListeners: [
            JitsiGenericListener(
                eventName: 'readyToClose',
                callback: (message) => debugPrint("readyToClose callback")),
          ]),
    );
  }

  void _onConferenceWillJoin(message) =>
      debugPrint("_onConferenceWillJoin broadcasted with message: $message");

  void _onConferenceJoined(message) =>
      debugPrint("_onConferenceJoined broadcasted with message: $message");

  void _onConferenceTerminated(message) =>
      debugPrint("_onConferenceTerminated broadcasted with message: $message");

  _onError(error) => debugPrint("_onError broadcasted: $error");
}
