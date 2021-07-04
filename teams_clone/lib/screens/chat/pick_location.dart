import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teams_clone/services/database.dart';
import 'package:teams_clone/shared/constants.dart';

class PickLocation extends StatefulWidget {
  const PickLocation({Key? key}) : super(key: key);

  @override
  _PickLocationState createState() => _PickLocationState();
}

class _PickLocationState extends State<PickLocation> {
  late double _w;
  late double _h;
  MapController _controller = MapController();
  @override
  Widget build(BuildContext context) {
    _w = MediaQuery.of(context).size.width;
    _h = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            _buildMap(),
            _buildCenterMarker(),
            _buildSendButton(),
            _buildBackButton()
          ],
        ),
      ),
    );
  }

  FlutterMap _buildMap() {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        center: LatLng(28.7041, 77.1025),
        zoom: 13.0,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
      ],
    );
  }

  Center _buildCenterMarker() {
    return Center(
      child: Icon(
        Icons.location_on_rounded,
        color: PURPLE_COLOR,
        size: 45,
      ),
    );
  }

  Container _buildSendButton() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(
        child: Text(
          "Send map pin",
          style: TextStyle(fontSize: _w * 0.04),
        ),
        onPressed: () async {
          Map<String, dynamic> result =
              await UserDBService.getAddressFromCoordinates(_controller.center);
          Navigator.pop(context, result);
        },
        style: ElevatedButton.styleFrom(
          primary: PURPLE_COLOR,
          fixedSize: Size(_w * 0.9, _h * 0.055),
        ),
      ),
    );
  }

  Positioned _buildBackButton() {
    return Positioned(
      top: _h * 0.015,
      left: _h * 0.015,
      child: FloatingActionButton(
        tooltip: "Back",
        onPressed: Navigator.of(context).pop,
        child: Icon(
          Icons.close_rounded,
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}
