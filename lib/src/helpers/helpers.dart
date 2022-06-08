library flutter_map.helpers;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart';

import '../../flutter_map.dart';

extension LatLngHelper on LatLng {
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
        (other.latitude - latitude),
        (other.longitude - longitude),
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

abstract class MapElement<T, W> {
  ///used in comparing
  final MapElementCallback<W>? onTap, onDrag;
  final String id;
  final T builder;

  MapElement(
      {required this.onTap,
      required this.onDrag,
      required this.id,
      required this.builder});

  W copyWithNewDelta(LatLng location);

  @override
  bool operator ==(Object other) {
    return other is MapElement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

typedef void MapElementCallback<W>(W element);
