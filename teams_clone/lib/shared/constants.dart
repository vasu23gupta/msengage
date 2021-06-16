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

ThemeData themeData = ThemeData(
  appBarTheme: AppBarTheme(
      actionsIconTheme: IconThemeData(color: Colors.black),
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(color: Colors.black)),
  floatingActionButtonTheme:
      FloatingActionButtonThemeData(backgroundColor: PURPLE_COLOR),
  bottomNavigationBarTheme:
      BottomNavigationBarThemeData(selectedItemColor: PURPLE_COLOR),
);
