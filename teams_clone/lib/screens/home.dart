import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/AppUser.dart';
import 'package:teams_clone/screens/chat/chat_home.dart';
import 'package:teams_clone/screens/meet/meet.dart';
import 'package:teams_clone/screens/more/calendar.dart';
import 'package:teams_clone/screens/profile.dart';
import 'package:teams_clone/services/auth.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    _appUser = AppUser.fromFirebaseUser(_user!);
    _userIcon = _user!.photoURL == null || _user!.photoURL!.isEmpty
        ? CircleAvatar(child: Text(_appUser.name.substring(0, 2).toUpperCase()))
        : CircleAvatar(
            backgroundImage:
                ImageDatabaseService.getImageByImageId(_user!.photoURL!));
    // AlanVoice.addButton(
    //     "2f5e93444b50a4a5677ea2c682b3f4d62e956eca572e1d8b807a3e2338fdd0dc/stage",
    //     buttonAlign: AlanVoice.BUTTON_ALIGN_LEFT);
    // AlanVoice.callbacks.add((command) => handleCommand(command.data!));
  }

  int _currentIndex = 1;
  late User? _user;
  List<String> _appBarTitles = ['Feed', 'Chat', 'Meet Now', 'More'];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AppUser _appUser;
  late CircleAvatar _userIcon;
  late double _h;
  late double _w;

  void _onPageChanged(int index) {
    if (index == 3) {
      showModalBottomSheet(
          context: context,
          builder: (context) {
            return Wrap(
              children: <Widget>[_buildCalendarButton()],
            );
          });
    } else {
      setState(() => _currentIndex = index);
    }
  }

  Padding _buildCalendarButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => Calendar())),
            child: Icon(Icons.calendar_today),
            style: ElevatedButton.styleFrom(
                primary: PURPLE_COLOR, fixedSize: Size(50, 50)),
          ),
          Text("Calendar")
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _h = MediaQuery.of(context).size.height;
    _w = MediaQuery.of(context).size.width;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        iconTheme: APPBAR_ICON_THEME,
        leading: IconButton(
          icon: _userIcon,
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        title: Text(_appBarTitles[_currentIndex], style: APPBAR_TEXT_STYLE),
        elevation: 0,
        actions: [
          IconButton(
              onPressed: () => joinMeeting(_appUser.name, _user!),
              icon: Icon(Icons.video_call_rounded))
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            SizedBox(height: _h * 0.03),
            ListTile(
              leading: _userIcon,
              title: Text(
                _user!.displayName == null
                    ? _user!.email!.split('@')[0]
                    : _user!.displayName!,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: _w * 0.045),
              ),
              trailing: Icon(Icons.navigate_next),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Profile(appUser: _appUser))),
            ),
            ListTile(
                title: Text('Logout'),
                onTap: () async => await AuthService.signOut()),
          ],
        ),
      ),
      body: Stack(
        children: [
          //Offstage(offstage: _currentIndex == 0, child: Activity(),),
          Offstage(
            offstage: _currentIndex != 1,
            child: ChatHome(),
          ),
          Offstage(
            offstage: _currentIndex != 2,
            child: Meeting(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        unselectedItemColor: Colors.grey,
        onTap: _onPageChanged,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Activity"),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_rounded), label: "Chat"),
          BottomNavigationBarItem(
              icon: Icon(Icons.video_call_outlined), label: "Meet"),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "More"),
        ],
      ),
    );
  }

  // handleCommand(Map<String, dynamic> res) {
  //   switch (res['command']) {
  //     case 'my events':
  //       Navigator.push(context, MaterialPageRoute(builder: (_) => Calendar()));
  //       break;

  //     case 'team chat':
  //       print(res);
  //       for (ChatRoom room in rooms) {
  //         if (room.name.toLowerCase().contains(res['room name']))
  //           Navigator.push(
  //               context, MaterialPageRoute(builder: (_) => Chat(room)));
  //         break;
  //       }
  //       break;

  //     case 'back':
  //       Navigator.pop(context);
  //       break;
  //   }
  // }
}
