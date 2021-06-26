class CalendarEvent {
  late String id;
  late String title;
  late DateTime startDate;
  late DateTime endDate;

  CalendarEvent.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    title = json['title'];
    startDate = DateTime.parse(json['startTime']).toLocal();
    endDate = DateTime.parse(json['endTime']).toLocal();
  }
}
