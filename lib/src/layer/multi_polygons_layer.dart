// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/helpers/gesture.dart';
import 'package:latlong2/latlong.dart' hide Path; // conflict with Path from UI

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/helpers/map_toolkit.dart';
import 'package:flutter_map/src/map/map.dart';

import '../helpers/helpers.dart';

class MultiPolygonLayerOptions extends LayerOptions<MultiPolygon> {
  final List<MultiPolygon> polygons;
  final bool polygonCulling;

  /// screen space culling of polygons based on bounding box
  MultiPolygonLayerOptions({
    Key? key,
    this.polygons = const [],
    this.polygonCulling = false,
    Stream<Null>? rebuild,
  }) : super(
          key: key,
          rebuild: rebuild,
        ) {
    if (polygonCulling) {
      for (var polygon in polygons) {
        polygon.boundingBox = LatLngBounds.fromPoints(
          [
            for (var item in polygon.points) ...item,
          ],
        );
      }
    }
  }
}

class MultiPolygon extends MapElement<MultiPolygonBuilder, MultiPolygon> {
  final List<List<LatLng>> points;
  final List<List<Offset>> offsets = [];
  late final LatLngBounds boundingBox;

  MultiPolygon({
    required String id,
    required MultiPolygonBuilder builder,
    required this.points,
    Function(MultiPolygon)? onTap,
    Function(MultiPolygon)? onDrag,
  }) : super(
          builder: builder,
          id: id,
          onDrag: onDrag,
          onTap: onTap,
        );
  @override
  MultiPolygon copyWithNewDelta(LatLng delta) {
    final newPoints = points.map((ee) {
      return ee
          .map(
            (e) => e.add(
              delta,
            ),
          )
          .toList();
    }).toList();
    return MultiPolygon(
      points: newPoints,
      id: id,
      builder: builder,
      onDrag: onDrag,
      onTap: onTap,
    );
  }
}

class MultiPolygonLayerWidget extends StatelessWidget {
  final MultiPolygonLayerOptions options;
  MultiPolygonLayerWidget({Key? key, required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return MultiPolygonLayer(
      options,
      mapState,
      options.rebuild,
    );
  }
}

class MultiPolygonLayer extends StatefulWidget {
  final MultiPolygonLayerOptions polygonOpts;
  final MapState map;
  final Stream<Null>? stream;

  MultiPolygonLayer(this.polygonOpts, this.map, this.stream)
      : super(key: polygonOpts.key);

  @override
  State<MultiPolygonLayer> createState() => _MultiPolygonLayerState();
}

class _MultiPolygonLayerState extends State<MultiPolygonLayer> {
  MultiPolygon? _draggingPolygon;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return StreamBuilder(
      stream: widget.stream, // a Stream<void> or null
      builder: (BuildContext context, _) {
        var polygons = <Widget>[];

        for (var polygon in widget.polygonOpts.polygons) {
          polygon.offsets.clear();

          if (widget.polygonOpts.polygonCulling &&
              !polygon.boundingBox.isOverlapping(widget.map.bounds)) {
            // skip this polygon as it's offscreen
            continue;
          }

          _fillOffsets(polygon.offsets, polygon.points);

          polygons.add(
            SizedBox.fromSize(
              size: size,
              child: polygon.builder(
                context,
                polygon.points,
                polygon.offsets,
              ),
            ),
          );
        }
        return FlutterMapLayerGestureListener(
          onDragStart: (details) {
            _draggingPolygon = _tapped(
              details.localFocalPoint,
              context,
              false,
            );
            if (_draggingPolygon == null) {
              return false;
            }
            setState(() {});
            return true;
          },
          onDragUpdate: (details) {
            if (_draggingPolygon == null) {
              return false;
            }
            final location = widget.map.offsetToLatLng(
              details.localFocalPoint - details.focalPointDelta,
              context.size!.width,
              context.size!.height,
            );
            final location2 = widget.map.offsetToLatLng(
              details.localFocalPoint,
              context.size!.width,
              context.size!.height,
            );

            final delta = location.difference(location2);

            widget.polygonOpts.polygons.remove(_draggingPolygon);

            _draggingPolygon = _draggingPolygon!.copyWithNewDelta(delta);
            widget.polygonOpts.polygons.add(_draggingPolygon!);

            widget.polygonOpts.doLayerRebuild();
            return true;
          },
          onDragEnd: (details) {
            if (_draggingPolygon == null) {
              return false;
            }
            _draggingPolygon!.onDrag!.call(_draggingPolygon!);
            setState(() {
              _draggingPolygon = null;
            });
            return true;
          },
          onTap: (details) {
            final tapped = _tapped(
              details.localPosition,
              context,
              false,
            );
            if (tapped == null) {
              return false;
            }
            tapped.onTap!.call(tapped);
            return true;
          },
          child: Stack(
            children: polygons,
          ),
        );
      },
    );
  }

  MultiPolygon? _tapped(Offset offset, BuildContext context, bool forTap) {
    final location = widget.map.offsetToLatLng(
      offset,
      context.size!.width,
      context.size!.height,
    );
    for (var p in widget.polygonOpts.polygons) {
      final valid = forTap ? p.onTap != null : p.onDrag != null;
      if (valid &&
          p.points.any(
            (points) => PolygonUtil.containsLocation(
              location,
              points,
              true,
            ),
          )) {
        if ((p.onDrag != null || p.onTap != null)) {
          return p;
        }
      }
    }
    return null;
  }

  void _fillOffsets(
    final List<List<Offset>> alloffsets,
    final List<List<LatLng>> allpoints,
  ) {
    for (var j = 0; j < allpoints.length; j++) {
      final offsets = <Offset>[];
      final points = allpoints[j];
      for (var i = 0, len = points.length; i < len; ++i) {
        var point = points[i];

        var pos = widget.map.project(point);
        pos = pos.multiplyBy(
                widget.map.getZoomScale(widget.map.zoom, widget.map.zoom)) -
            widget.map.getPixelOrigin();
        offsets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
        if (i > 0) {
          offsets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
        }
      }
      alloffsets.add(offsets);
    }
  }
}

/* class MultiPolygonGestureDetector
    extends MapElementGestureDetector<MultiPolygon> {
  MultiPolygonGestureDetector(
      {required List<MultiPolygon> polygons,
      required MapState mapState,
      required Widget child,
      required void Function(MultiPolygon p1, ScaleStartDetails p2)
          onDragStartOnPolygon,
      required void Function(MultiPolygon p1) onTapOnPolygon,
      required void Function(MultiPolygon p1, ScaleUpdateDetails p2)
          onDragUpdateOnPolygon,
      required void Function() onDragEndOnPolygon})
      : super(
          polygons: polygons,
          mapState: mapState,
          child: child,
          onDragStartOnPolygon: onDragStartOnPolygon,
          onTapOnPolygon: onTapOnPolygon,
          onDragUpdateOnPolygon: onDragUpdateOnPolygon,
          onDragEndOnPolygon: onDragEndOnPolygon,
        );

  @override
  MultiPolygon? tapped(Offset offset, BuildContext context, bool forTap) {
    final location = mapState.offsetToLatLng(
      offset,
      context.size!.width,
      context.size!.height,
    );
    for (var p in polygons) {
      if (p.points.any(
        (points) => PolygonUtil.containsLocation(
          location,
          points,
          true,
        ),
      )) {
        if ((p.onDrag != null || p.onTap != null)) {
          return p;
        }
      }
    }
    return null;
  }
}

abstract class MapElementGestureDetector<MapElemementType extends MapElement>
    extends StatefulWidget {
  final List<MapElemementType> polygons;
  final MapState mapState;
  final Widget child;
  final void Function(MapElemementType, ScaleStartDetails) onDragStartOnPolygon;
  final void Function(MapElemementType, ScaleUpdateDetails)
      onDragUpdateOnPolygon;
  final void Function() onDragEndOnPolygon;
  final void Function(MapElemementType) onTapOnPolygon;
  const MapElementGestureDetector({
    Key? key,
    required this.polygons,
    required this.mapState,
    required this.child,
    required this.onDragStartOnPolygon,
    required this.onTapOnPolygon,
    required this.onDragUpdateOnPolygon,
    required this.onDragEndOnPolygon,
  }) : super(key: key);

  MapElemementType? tapped(Offset offset, BuildContext context, bool forTap);

  @override
  State<MapElementGestureDetector<MapElemementType>> createState() =>
      _MapElementGestureDetectorState<MapElemementType>();
}

class _MapElementGestureDetectorState<MapElemementType extends MapElement>
    extends State<MapElementGestureDetector<MapElemementType>> {
  MapElemementType? tapped;
  @override
  Widget build(BuildContext context) {
    return LayerGestureListener(
      child: widget.child,
      onDragStart: (details) {
        tapped = widget.tapped(details.localFocalPoint, context, false);
        if (tapped != null) {
          widget.onDragStartOnPolygon.call(tapped!, details);
          return true;
        } else {
          return false;
        }
      },
      onDragUpdate: (details) {
        if (tapped != null) {
          widget.onDragUpdateOnPolygon.call(tapped!, details);
          return true;
        } else {
          return false;
        }
      },
      onDragEnd: (details) {
        tapped = null;
        widget.onDragEndOnPolygon.call();
        return true;
      },
      onTap: (details) {
        final p = widget.tapped(details.localPosition, context, true);
        if (p != null) {
          widget.onTapOnPolygon.call(p);
          return true;
        }
        return false;
      },
    );
  }
}
 */
typedef MultiPolygonBuilder = Widget Function(
  BuildContext context,
  List<List<LatLng>> points,
  List<List<Offset>> offsets,
);

class MultiPolygonWidget extends StatefulWidget {
  final Color borderColor, color;
  final double borderStrokeWidth;
  final bool dottedBorder, disableHolesBorder;
  final List<List<LatLng>> points;
  final List<List<Offset>> offsets;
  MultiPolygonWidget({
    Key? key,
    required this.points,
    required this.offsets,
    this.borderColor = Colors.black,
    this.color = Colors.blue,
    this.borderStrokeWidth = 1.0,
    this.dottedBorder = false,
    this.disableHolesBorder = true,
  }) : super(key: key);

  @override
  State<MultiPolygonWidget> createState() => _MultiPolygonWidgetState();
}

class _MultiPolygonWidgetState extends State<MultiPolygonWidget> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MultiPolygonPainter(
        borderColor: widget.borderColor,
        color: widget.color,
        borderStrokeWidth: widget.borderStrokeWidth,
        dottedBorder: widget.dottedBorder,
        allpoints: widget.points,
        alloffsets: widget.offsets,
      ),
    );
  }
}

class MultiPolygonPainter extends CustomPainter {
  final Color borderColor, color;
  final double borderStrokeWidth;
  final bool dottedBorder;
  final List<List<LatLng>> allpoints;
  final List<List<Offset>> alloffsets;

  MultiPolygonPainter({
    required this.borderColor,
    required this.color,
    required this.borderStrokeWidth,
    required this.dottedBorder,
    required this.allpoints,
    required this.alloffsets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var offsets in alloffsets) {
      if (offsets.isNotEmpty) {
        final rect = Offset.zero & size;
        _paintPolygon(
          canvas,
          rect,
          offsets,
        );
      }
    }
  }

  void _paintBorder(Canvas canvas, List<Offset> offsets) {
    if (borderStrokeWidth > 0.0) {
      var borderRadius = (borderStrokeWidth / 2);

      final borderPaint = Paint()
        ..color = borderColor
        ..strokeWidth = borderStrokeWidth;

      if (dottedBorder) {
        var spacing = borderStrokeWidth * 1.5;
        _paintDottedLine(canvas, offsets, borderRadius, spacing, borderPaint);
      } else {
        _paintLine(canvas, offsets, borderRadius, borderPaint);
      }
    }
  }

  void _paintDottedLine(Canvas canvas, List<Offset> offsets, double radius,
      double stepLength, Paint paint) {
    var startDistance = 0.0;
    for (var i = 0; i < offsets.length - 1; i++) {
      var o0 = offsets[i];
      var o1 = offsets[i + 1];
      var totalDistance = _dist(o0, o1);
      var distance = startDistance;
      while (distance < totalDistance) {
        var f1 = distance / totalDistance;
        var f0 = 1.0 - f1;
        var offset = Offset(o0.dx * f0 + o1.dx * f1, o0.dy * f0 + o1.dy * f1);
        canvas.drawCircle(offset, radius, paint);
        distance += stepLength;
      }
      startDistance = distance < totalDistance
          ? stepLength - (totalDistance - distance)
          : distance - totalDistance;
    }
    canvas.drawCircle(offsets.last, radius, paint);
  }

  void _paintLine(
      Canvas canvas, List<Offset> offsets, double radius, Paint paint) {
    canvas.drawPoints(PointMode.lines, [...offsets, offsets[0]], paint);
    for (var offset in offsets) {
      canvas.drawCircle(offset, radius, paint);
    }
  }

  void _paintPolygon(
    Canvas canvas,
    Rect rect,
    List<Offset> offsets,
  ) {
    final paint = Paint();

    canvas.clipRect(rect);
    paint
      ..style = PaintingStyle.fill
      ..color = color;

    var path = Path();
    path.addPolygon(offsets, true);
    canvas.drawPath(path, paint);

    _paintBorder(
      canvas,
      offsets,
    );
  }

  @override
  bool shouldRepaint(MultiPolygonPainter other) => false;

  double _dist(Offset v, Offset w) {
    return sqrt(_dist2(v, w));
  }

  double _dist2(Offset v, Offset w) {
    return _sqr(v.dx - w.dx) + _sqr(v.dy - w.dy);
  }

  double _sqr(double x) {
    return x * x;
  }
}
