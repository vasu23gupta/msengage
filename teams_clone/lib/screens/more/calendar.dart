import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:teams_clone/models/CalendarEvent.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/more/create_event.dart';
import 'package:teams_clone/screens/more/event_details.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';

class Calendar extends StatefulWidget {
  final ChatRoom? room;
  const Calendar({this.room});
  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  ChatRoom? _room;
  User? _user;
  bool _loading = true;
  late List<CalendarEvent> _events;

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    _room = widget.room;
    getEvents();
  }

  Future<void> getEvents() async {
    if (_room == null) {
      _events = await CalendarDatabaseService.getEventFromUserId(_user!.uid);
    } else {
      _room!.events.clear();
      for (String eventId in _room!.eventIds)
        _room!.events
            .add(await CalendarDatabaseService.getEventFromEventId(eventId));

      _events = _room!.events;
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => _loading
      ? const Center(child: CircularProgressIndicator())
      : Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.black),
            title: Text(MONTHS_FULL[DateTime.now().month - 1],
                style: TextStyle(color: Colors.black, fontSize: 17)),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreateEvent(room: _room))),
            child: Icon(Icons.add),
          ),
          body: ListView(children: <Widget>[
            SizedBox(
              height: 10,
            ),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(Duration(days: 150)),
              focusedDay: DateTime.now(),
              availableGestures: AvailableGestures.all,
              headerVisible: false,
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _events.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(_events[i].title),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EventDetails(
                          _events[i],
                          room: _room,
                        ))),
              ),
            ),
          ]));
}
