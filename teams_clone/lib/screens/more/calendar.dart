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
  DateTime? _lastDate;
  List<Widget> _eventWidgets = [];
  late double _w;
  late double _h;

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    _room = widget.room;
    // _w = MediaQuery.of(context).size.width;
    // _h = MediaQuery.of(context).size.height;
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
    _events.sort((a, b) => a.startDate.isAfter(b.startDate) ? 1 : -1);
    for (CalendarEvent event in _events) {
      if (_lastDate == null || !isSameDay(_lastDate!, event.startDate))
        _eventWidgets.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  '${event.startDate.day} ${MONTHS_3CHAR[event.startDate.month - 1]}  ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: _w * 0.05),
                ),
                Text(
                  '${DAYS_FULL[event.startDate.weekday - 1]}',
                  style: TextStyle(fontSize: _w * 0.04),
                )
              ],
            ),
          ),
        );
      _eventWidgets.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: ListTile(
              title: Text(event.title, style: TextStyle(fontSize: _w * 0.05)),
              subtitle: Text(
                "${event.startDate.hour}:${event.startDate.minute} - ${event.endDate.day} ${MONTHS_3CHAR[event.endDate.month - 1]} ${event.endDate.year}, ${event.endDate.hour}:${event.endDate.minute}",
                style: TextStyle(color: Colors.black),
              ),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => EventDetails(event, room: _room))),
            ),
          ),
        ),
      );
      _lastDate = event.startDate;
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    _w = MediaQuery.of(context).size.width;
    _h = MediaQuery.of(context).size.height;
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              iconTheme: APPBAR_ICON_THEME,
              title: Text(MONTHS_FULL[DateTime.now().month - 1],
                  style: APPBAR_TEXT_STYLE),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CreateEvent(room: _room))),
              child: Icon(Icons.add),
            ),
            body: ListView(
              children: <Widget>[
                SizedBox(height: 10),
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(Duration(days: 150)),
                  focusedDay: DateTime.now(),
                  availableGestures: AvailableGestures.all,
                  headerVisible: false,
                ),
                ListView(
                  shrinkWrap: true,
                  children: _eventWidgets,
                ),
              ],
            ),
          );
  }

  bool isSameDay(DateTime a, DateTime b) {
    if (a.day == b.day && a.month == b.month && a.year == b.year) return true;
    return false;
  }
}
