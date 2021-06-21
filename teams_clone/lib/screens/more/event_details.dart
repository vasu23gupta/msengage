import 'package:flutter/material.dart';
import 'package:teams_clone/models/CalendarEvent.dart';
import 'package:teams_clone/models/ChatRoom.dart';
import 'package:teams_clone/screens/more/calendar.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';

class EventDetails extends StatelessWidget {
  final CalendarEvent event;
  final ChatRoom? room;
  const EventDetails(this.event, {this.room});

  @override
  Widget build(BuildContext context) {
    final _sd = event.startDate;
    final _ed = event.endDate;
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        title: Text("Event details",
            style: TextStyle(color: Colors.black, fontSize: 17)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(event.title, style: TextStyle(fontSize: 35)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "${_sd.hour}:${_sd.minute} ${DAYS_3CHAR[_sd.weekday - 1]} ${MONTHS_3CHAR[_sd.month - 1]} ${_sd.day}, ${_sd.year} - ",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "${_ed.hour}:${_ed.minute} ${DAYS_3CHAR[_ed.weekday - 1]} ${MONTHS_3CHAR[_ed.month - 1]} ${_ed.day}, ${_ed.year}",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {},
                child: Text("Edit"),
                style: OutlinedButton.styleFrom(
                  primary: PURPLE_COLOR,
                  side: BorderSide(color: PURPLE_COLOR),
                  fixedSize: Size(80, 40),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text("Cancel event"),
              onTap: () async {
                bool done =
                    await CalendarDatabaseService.deleteEventFromEventId(
                        event.id);
                if (done && room != null) {
                  room!.eventIds.remove(event.id);
                }
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => Calendar(room: room)));
              },
            )
          ],
        ),
      ),
    );
  }
}
