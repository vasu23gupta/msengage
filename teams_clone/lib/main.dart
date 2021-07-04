import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:teams_clone/screens/wrapper.dart';
import 'package:teams_clone/services/auth.dart';
import 'package:teams_clone/shared/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        title: 'Teams Clone',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: lightThemeData,
        home: Wrapper(),
      ),
    );
  }
}
