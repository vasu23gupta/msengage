import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/AppUser.dart';
import 'package:teams_clone/screens/chat/chat_home.dart';
import 'package:teams_clone/screens/meet/meet.dart';
import 'package:teams_clone/screens/more/calendar.dart';
import 'package:teams_clone/services/auth.dart';

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
  }

  int _currentIndex = 1;
  late User? _user;
  List<String> _appBarTitles = ['Feed', 'Chat', 'Meet Now', 'More'];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AppUser _appUser;

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
          Container(
            height: 50,
            width: 50,
            child: ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => Calendar())),
                child: Icon(Icons.calendar_today)),
          ),
          Text("Calendar")
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: _appUser.icon,
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        title: Text(_appBarTitles[_currentIndex],
            style: TextStyle(color: Colors.black, fontSize: 17)),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
              leading: _appUser.icon,
              title: Text(_user!.displayName!),
              trailing: Icon(Icons.navigate_next),
              onTap: () {},
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
        //selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onPageChanged,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Activity",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_rounded),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_call_outlined),
            label: "Meet",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: "More",
          ),
        ],
      ),
    );
  }
}
