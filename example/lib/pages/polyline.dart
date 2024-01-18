import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class PolylinePage extends StatelessWidget {
  static const String route = 'polyline';

  @override
  Widget build(BuildContext context) {
    var points = <List<LatLng>>[
      [
        LatLng(51.5, -0.09),
        LatLng(53.3498, -6.2603),
        LatLng(48.8566, 2.3522),
      ],
      [
        LatLng(52.5, -1.09),
        LatLng(54.3498, -5.2603),
        LatLng(49.8566, 1.3522),
      ],
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Polylines')),
      drawer: buildDrawer(context, PolylinePage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('Polylines'),
            ),
            Flexible(
              child: FlutterMapMasterGestureDetector(
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(51.5, -0.09),
                    zoom: 5.0,
                  ),
                  layers: [
                    TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MultiPolylineLayerOptions(
                      multiPolylines: [
                        MultiPolyline(
                          id: '4',
                          points: points,
                          onTap: (_) {
                            print('polyline tapped : ${DateTime.now().toIso8601String()}');
                          },
                          builder: (context, points, offsets, boundingBox) {
                            return MultiPolylineWidget(
                              points: points,
                              offsets: offsets,
                              boundingBox: boundingBox,
                              strokeWidth: 4.0,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
