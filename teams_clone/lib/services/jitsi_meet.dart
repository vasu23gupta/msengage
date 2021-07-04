import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:jitsi_meet/jitsi_meet.dart';

class MeetingService {
  /// Replace all characters which are not alphanumeric and not - or _ with _
  /// in [email] to make it compatible for jitsi room id;
  static String emailToJitsiRoomId(String email) {
    return email.replaceAll(RegExp("[^a-zA-Z0-9-_]"), "_");
  }

  /// Join jitsi meeting with room id [roomId], room name [name] and user's
  /// display name from [user]
  static joinMeeting(String roomId, User user, {String? name}) async {
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
    var options = JitsiMeetingOptions(room: roomId)
      ..subject = name
      ..userDisplayName = user.displayName
      ..featureFlags.addAll(featureFlags)
      ..webOptions = {
        "roomName": roomId,
        "subject": name,
        "width": "100%",
        "height": "100%",
        "enableWelcomePage": false,
        "chromeExtensionBanner": null,
        "userInfo": {"displayName": user.displayName}
      };

    print("JitsiMeetingOptions: $options");
    await JitsiMeet.joinMeeting(options);
  }
}
