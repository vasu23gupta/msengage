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
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                center: LatLng(28.7041, 77.1025),
                zoom: 13.0,
              ),
              layers: [
                TileLayerOptions(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
              ],
            ),
            Center(
              child: Icon(
                Icons.location_on_rounded,
                color: PURPLE_COLOR,
                size: 45,
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                child: Text(
                  "Send map pin",
                  style: TextStyle(fontSize: _w * 0.04),
                ),
                onPressed: () async {
                  Map<String, dynamic> result =
                      await Utils.reverseGeocode(_controller.center);
                  Navigator.pop(context, result);
                },
                style: ElevatedButton.styleFrom(
                  primary: PURPLE_COLOR,
                  fixedSize: Size(_w * 0.9, _h * 0.055),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
