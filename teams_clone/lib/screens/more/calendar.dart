import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:teams_clone/models/CalendarEvent.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/home.dart';
import 'package:teams_clone/screens/more/create_event.dart';
import 'package:teams_clone/screens/more/event_details.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
  late List<Widget> _eventWidgets;
  late double _w;
  late double _h;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  HashMap<int, int> _datesAndHeadingIndices = HashMap();

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    _room = widget.room;
    _eventWidgets = <Widget>[SizedBox(height: 10), _buildTableCalendar()];
    getEvents();
  }

  TableCalendar<dynamic> _buildTableCalendar() {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(Duration(days: 150)),
      focusedDay: DateTime.now(),
      availableGestures: AvailableGestures.all,
      headerVisible: false,
      onDaySelected: (a, b) => _itemScrollController.scrollTo(
        index: _datesAndHeadingIndices[_dateToNumber(b)]!,
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> getEvents() async {
    if (_room == null) {
      _events = await CalendarDatabaseService.getEventFromUserId(_user!.uid);
    } else {
      _room = await ChatDatabaseService.getChatRoomByRoomId(_room!.roomId);

      for (String eventId in _room!.eventIds)
        _room!.events
            .add(await CalendarDatabaseService.getEventFromEventId(eventId));

      _events = _room!.events;
    }
    _events.sort((a, b) => a.startDate.isAfter(b.startDate) ? 1 : -1);
    _buildWidgets();
    setState(() => _loading = false);
  }

  void _buildWidgets() {
    for (CalendarEvent event in _events) {
      if (_lastDate == null || !isSameDay(_lastDate!, event.startDate)) {
        _eventWidgets.add(_buildDateHeading(event.startDate));
        _datesAndHeadingIndices[_dateToNumber(event.startDate)] =
            _eventWidgets.length - 1;
      }
      _eventWidgets.add(_buildEventTile(event));
      _lastDate = event.startDate;
    }
  }

  Padding _buildDateHeading(DateTime dateTime) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(
            '${dateTime.day} ${MONTHS_3CHAR[dateTime.month - 1]}  ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: _w * 0.05),
          ),
          Text(
            '${DAYS_FULL[dateTime.weekday - 1]}',
            style: TextStyle(fontSize: _w * 0.04),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _w = MediaQuery.of(context).size.width;
    _h = MediaQuery.of(context).size.height;
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: _buildAppBar(context),
            floatingActionButton: _buildAddFAB(),
            body: _buildListView(),
          );
  }

  ScrollablePositionedList _buildListView() {
    return ScrollablePositionedList.builder(
      itemCount: _eventWidgets.length,
      itemBuilder: (context, index) => _eventWidgets[index],
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
    );
  }

  FloatingActionButton _buildAddFAB() {
    return FloatingActionButton(
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => CreateEvent(room: _room))),
      child: Icon(Icons.add),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      iconTheme: APPBAR_ICON_THEME,
      title:
          Text(MONTHS_FULL[DateTime.now().month - 1], style: APPBAR_TEXT_STYLE),
      bottom: buildSearchBar(context),
    );
  }

  int _dateToNumber(DateTime dateTime) {
    int res = 0;
    res += dateTime.year;
    res += dateTime.month * 10000;
    res += dateTime.day * 1000000;
    return res;
  }

  Widget _buildEventTile(CalendarEvent event) {
    return Padding(
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
    );
  }
}
