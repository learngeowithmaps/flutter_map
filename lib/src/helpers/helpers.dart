library flutter_map.helpers;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart';

import '../../flutter_map.dart';

extension LatLngHelper on LatLng {
  static List<LatLng> pointsWithDelta(
    List<LatLng> points,
    LatLng delta,
  ) {
    if (delta == LatLng.zero()) {
      return points;
    }
    try {
      return points
          .map(
            (e) => e.add(
              delta,
            ),
          )
          .toList();
    } catch (e) {
      return points;
    }
  }

  static List<List<LatLng>> pointsListWithDelta(
    List<List<LatLng>> points,
    LatLng delta,
  ) {
    if (delta == LatLng.zero()) {
      return points;
    }
    try {
      return points.map((ee) {
        return ee
            .map(
              (e) => e.add(
                delta,
              ),
            )
            .toList();
      }).toList();
    } catch (e) {
      return points;
    }
  }

  static LatLng centerOfListOfPoints(
    List<LatLng> list,
  ) {
    var lat = 0.0;
    var lng = 0.0;
    for (final point in list) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / list.length, lng / list.length);
  }

  LatLng difference(LatLng other, {bool remainder = true}) {
    if (!remainder) {
      return LatLng(
        (latitude - other.latitude),
        (longitude - other.longitude),
      );
    }
    return LatLng(
      (other.latitude - latitude).remainder(90),
      (other.longitude - longitude).remainder(180),
    );
  }

  LatLng add(LatLng other, {bool remainder = true}) {
    if (!remainder) {
      return LatLng(
        (latitude + other.latitude),
        (longitude + other.longitude),
      );
    }
    return LatLng(
      (latitude + other.latitude).remainder(90),
      (longitude + other.longitude).remainder(180),
    );
  }
}

abstract class MapElement<WidgetType, MapElementType> {
  ///used in comparing
  final Function(MapElementType)? onTap, onDrag;
  final String id;
  final WidgetType builder;
  final LatLng delta;

  MapElement({
    required this.delta,
    required this.onTap,
    required this.onDrag,
    required this.id,
    required this.builder,
  });

  MapElementType copyWithNewDelta(LatLng location);

  @override
  bool operator ==(Object other) {
    return other is MapElement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
