import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class HomePage extends StatelessWidget {
  static const String route = '/';

  @override
  Widget build(BuildContext context) {
    var polygons = <Polygon>[
      Polygon(
        id: "1",
        points: [LatLng(51.5, -0.09), LatLng(54.5, -1.09), LatLng(56.5, -3.09)],
        builder: (
          context,
          points,
          holePointsList,
          holeOffsetsList,
        ) {
          return PolygonWidget(points: points);
        },
      ),
    ];
    var markers = <Marker>[
      Marker(
        id: "2",
        width: 80.0,
        height: 80.0,
        point: LatLng(53.3498, -6.2603),
        builder: (ctx) => Container(
          child: Text("two"),
        ),
      ),
      Marker(
        id: "3",
        width: 80.0,
        height: 80.0,
        point: LatLng(48.8566, 2.3522),
        builder: (ctx) => Container(
          child: Text("three"),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('This is a map that is showing (51.5, -0.9).'),
            ),
            Flexible(
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
                    // For example purposes. It is recommended to use
                    // TileProvider with a caching and retry strategy, like
                    // NetworkTileProvider or CachedNetworkTileProvider
                    tileProvider: NonCachingNetworkTileProvider(),
                  ),
                  MarkerLayerOptions(
                    markers: markers,
                  ),
                  PolygonLayerOptions(
                    polygons: polygons,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
