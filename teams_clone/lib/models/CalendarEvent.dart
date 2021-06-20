class CalendarEvent {
  late String title;
  late DateTime startDate;
  late DateTime endDate;

  CalendarEvent.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    startDate = DateTime.parse(json['startTime']);
    endDate = DateTime.parse(json['endTime']);
  }
}
