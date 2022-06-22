import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  @override
<<<<<<< HEAD
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var polygons = <MultiPolygon>[];
  final polygonRebuild = StreamController<Null>();
  var markers = <MultiMarker>[
    MultiMarker(
      id: "2",
      width: 80.0,
      height: 80.0,
      onDrag: (_) {},
      onTap: (_) {
        print("TAPPED" + DateTime.now().toIso8601String());
      },
      points: [
        LatLng(53.3498, -6.2603),
        LatLng(48.8566, 2.3522),
      ],
      builder: (ctx) => Container(
        color: Colors.red,
      ),
    ),
  ];

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 4), () {
      polygons.addAll(<MultiPolygon>[
        MultiPolygon(
          onDrag: (_) {},
          onTap: (_) {},
          id: "6",
          points: [
            [
              LatLng(51.5, -0.09),
              LatLng(56.5, -2.09),
              LatLng(59.5, -5.09),
            ],
            [
              LatLng(61.5, -0.09),
              LatLng(66.5, -2.09),
              LatLng(69.5, -5.09),
            ],
=======
  Widget build(BuildContext context) {
    var polygons = <MultiPolygon>[
      MultiPolygon(
        onDrag: () {},
        onTap: () {},
        id: "6",
        points: [
          [
            LatLng(51.5, -0.09),
            LatLng(56.5, -2.09),
            LatLng(59.5, -5.09),
          ],
          [
            LatLng(61.5, -0.09),
            LatLng(66.5, -2.09),
            LatLng(69.5, -5.09),
          ],
        ],
        builder: (
          context,
          points,
          offsets,
        ) {
          return MultiPolygonWidget(
            points: points,
            offsets: offsets,
          );
        },
      ),
      MultiPolygon(
        onDrag: () {
          print("polygon dragged" + DateTime.now().toIso8601String());
        },
        onTap: () {
          print("polygon tapped" + DateTime.now().toIso8601String());
        },
        id: "7",
        points: [
          [
            LatLng(41.5, -0.09),
            LatLng(46.5, -2.09),
            LatLng(49.5, -5.09),
>>>>>>> 7c0201a770901a7a1a614b17dba07a3b91f9ffb0
          ],
          builder: (
            context,
            points,
            offsets,
          ) {
            return MultiPolygonWidget(
              points: points,
              offsets: offsets,
            );
          },
        ),
        MultiPolygon(
          onDrag: (_) {
            print("polygon dragged" + DateTime.now().toIso8601String());
          },
          onTap: (_) {
            print("polygon tapped" + DateTime.now().toIso8601String());
          },
          id: "7",
          points: [
            [
              LatLng(41.5, -0.09),
              LatLng(46.5, -2.09),
              LatLng(49.5, -5.09),
            ],
            [
              LatLng(31.5, -0.09),
              LatLng(36.5, -2.09),
              LatLng(39.5, -5.09),
            ],
          ],
<<<<<<< HEAD
          builder: (
            context,
            points,
            offsets,
          ) {
            return MultiPolygonWidget(
              points: points,
              offsets: offsets,
            );
          },
=======
        ],
        builder: (
          context,
          points,
          offsets,
        ) {
          return MultiPolygonWidget(
            points: points,
            offsets: offsets,
          );
        },
      ),
    ];
    var markers = <MultiMarker>[
      MultiMarker(
        id: "2",
        width: 80.0,
        height: 80.0,
        onDrag: () {},
        onTap: () {
          print("TAPPED" + DateTime.now().toIso8601String());
        },
        points: [
          LatLng(53.3498, -6.2603),
          LatLng(48.8566, 2.3522),
        ],
        builder: (ctx) => Container(
          color: Colors.red,
>>>>>>> 7c0201a770901a7a1a614b17dba07a3b91f9ffb0
        ),
      ]);
      polygonRebuild.add(null);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      drawer: buildDrawer(context, HomePage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('This is a map that is showing (51.5, -0.9).'),
            ),
            Flexible(
              child: FlutterMapMasterGestureDetector(
                child: FlutterMap(
                  key: ValueKey(DateTime.now()),
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
                    MultiPolygonLayerOptions(
                      polygons: polygons,
                      rebuild: polygonRebuild.stream,
                    ),
                    MultiMarkerLayerOptions(
                      multiMarkers: markers,
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
