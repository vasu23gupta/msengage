import 'package:flutter/material.dart';

const textInputDecoration = InputDecoration(
  counterText: "",
  //fillColor: Colors.white,
  filled: true,
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(
      //color: Colors.white,
      width: 2.0,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(
      //color: Colors.pink,
      width: 2.0,
    ),
  ),
);

const PURPLE_COLOR = Color(0xff505AC9);
const APPBAR_ICON_THEME = IconThemeData(color: Colors.black);
const APPBAR_TEXT_STYLE = TextStyle(color: Colors.black, fontSize: 17);

ThemeData themeData = ThemeData(
  appBarTheme: AppBarTheme(
      actionsIconTheme: APPBAR_ICON_THEME,
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(color: Colors.black)),
  floatingActionButtonTheme:
      FloatingActionButtonThemeData(backgroundColor: PURPLE_COLOR),
  bottomNavigationBarTheme:
      BottomNavigationBarThemeData(selectedItemColor: PURPLE_COLOR),
);

const String DEFAULT_GROUP_IMG = "assets/default_group_icon.png";

const List<String> DAYS_3CHAR = [
  "Mon",
  "Tue",
  "Wed",
  "Thu",
  "Fri",
  "Sat",
  "Sun"
];

const List<String> DAYS_FULL = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday"
];

const List<String> MONTHS_3CHAR = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec"
];

const List<String> MONTHS_FULL = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December"
];
