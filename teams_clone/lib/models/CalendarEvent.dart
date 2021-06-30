/// For all events and reminders.
class CalendarEvent {
  /// id of the event.
  late String _id;

  /// title of the event.
  late String _title;

  /// date and time of start of event.
  late DateTime _startDate;

  /// date and time of end of event.
  late DateTime _endDate;

  /// to make event from mongo document.
  CalendarEvent.fromJson(Map<String, dynamic> json) {
    _id = json['_id'];
    _title = json['title'];
    _startDate = DateTime.parse(json['startTime']).toLocal();
    _endDate = DateTime.parse(json['endTime']).toLocal();
  }

  /// get id of event.
  String get id => _id;

  /// get title of event.
  String get title => _title;

  /// get date and time of start of event.
  DateTime get startDate => _startDate;

  /// get date and time of end of event.
  DateTime get endDate => _endDate;
}
