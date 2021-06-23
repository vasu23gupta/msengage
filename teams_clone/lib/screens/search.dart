import 'package:flutter/material.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        title: TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: Navigator.of(context).pop,
            ),
            hintText: "Search",
            fillColor: Colors.grey[200],
            filled: true,
          ),
        ),
      ),
    );
  }
}
