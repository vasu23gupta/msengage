import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teams_clone/models/CalendarEvent.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/more/calendar.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';

class CreateEvent extends StatefulWidget {
  final ChatRoom? room;
  const CreateEvent({this.room});
  @override
  _CreateEventState createState() => _CreateEventState();
}

class _CreateEventState extends State<CreateEvent> {
  TextEditingController _titleController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _nowDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TimeOfDay _nowTime;
  ChatRoom? _room;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = Provider.of<User?>(context, listen: false);
    _nowDate = DateTime.now();
    _startDate = _nowDate;
    _endDate = _startDate;
    _nowTime = TimeOfDay.now();
    _startTime = _nowTime;
    _endTime = _startTime;
    _room = widget.room;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        title: Text("New event",
            style: TextStyle(color: Colors.black, fontSize: 17)),
        actions: <Widget>[
          IconButton(
              onPressed: () async {
                CalendarEvent event = await CalendarDatabaseService.createEvent(
                    DateTime(_startDate.year, _startDate.month, _startDate.day,
                        _startTime.hour, _startTime.minute),
                    DateTime(_endDate.year, _endDate.month, _endDate.day,
                        _endTime.hour, _endTime.minute),
                    _titleController.text,
                    _user!.uid,
                    _room == null ? "" : _room!.roomId);
                if (_room != null) {
                  _room!.eventIds.add(event.id);
                  _room!.events.add(event);
                }
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Calendar(room: _room)));
              },
              icon: Icon(Icons.check))
        ],
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.edit),
            title: TextField(
              decoration: InputDecoration(hintText: "Title"),
              controller: _titleController,
            ),
          ),
          _buildStartDateTile(),
          _buildEndDateTile(),
        ],
      ),
    );
  }

  ListTile _buildStartDateTile() => ListTile(
        leading: SizedBox(width: 24),
        title: TextButton(
          style: ButtonStyle(alignment: Alignment.centerLeft),
          onPressed: () async {
            _startDate = (await showDatePicker(
              context: context,
              initialDate: _nowDate,
              firstDate: _nowDate,
              lastDate: _nowDate.add(Duration(days: 1825)), // 5*365 ~ 5years
            ))!;
            if (_startDate.isAfter(_endDate))
              _endDate = DateTime.parse(_startDate.toString());
            setState(() {});
          },
          child: Text(
            "${DAYS_3CHAR[_startDate.weekday - 1]}, ${_startDate.day} ${MONTHS_3CHAR[_startDate.month - 1]} ${_startDate.year}",
            style: TextStyle(color: Colors.black),
          ),
        ),
        trailing: TextButton(
          onPressed: () async {
            _startTime = (await showTimePicker(
                context: context, initialTime: _nowTime))!;
            if (!_endDate.isAfter(_startDate) &&
                _timeOfDayToDouble(_startTime) > _timeOfDayToDouble(_endTime))
              _endTime =
                  TimeOfDay(hour: _startTime.hour, minute: _startTime.minute);
            setState(() {});
          },
          child: Text(
            "${_startTime.hourOfPeriod}:${_startTime.minute} ${_startTime.period.index == 0 ? "AM" : "PM"}",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );

  ListTile _buildEndDateTile() => ListTile(
        leading: SizedBox(width: 24),
        title: TextButton(
          style: ButtonStyle(alignment: Alignment.centerLeft),
          onPressed: () async {
            _endDate = (await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: _startDate,
              lastDate: _nowDate.add(Duration(days: 1825)), // 5*365 ~ 5years
            ))!;
            setState(() {});
          },
          child: Text(
            "${DAYS_3CHAR[_endDate.weekday - 1]}, ${_endDate.day} ${MONTHS_3CHAR[_endDate.month - 1]} ${_endDate.year}",
            style: TextStyle(color: Colors.black),
          ),
        ),
        trailing: TextButton(
          onPressed: () async {
            _endTime = (await showTimePicker(
                context: context, initialTime: _nowTime))!;
            if (!_endDate.isAfter(_startDate) &&
                _timeOfDayToDouble(_startTime) > _timeOfDayToDouble(_endTime))
              _endTime =
                  TimeOfDay(hour: _startTime.hour, minute: _startTime.minute);
            setState(() {});
          },
          child: Text(
            "${_endTime.hourOfPeriod}:${_endTime.minute} ${_endTime.period.index == 0 ? "AM" : "PM"}",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );

  double _timeOfDayToDouble(TimeOfDay myTime) =>
      myTime.hour + myTime.minute / 60.0;
}
