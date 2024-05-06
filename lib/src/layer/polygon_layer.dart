import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/helpers/map_toolkit.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../helpers/helpers.dart';

class PolygonLayerOptions extends LayerOptions<Polygon> {
  final List<Polygon> polygons;
  final bool polygonCulling;

  /// screen space culling of polygons based on bounding box
  PolygonLayerOptions({
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
        polygon.boundingBox = LatLngBounds.fromPoints(polygon.points);
      }
    }
  }
}

typedef PolygonCallback = Null Function(Polygon);

class Polygon extends MapElement<PolygonBuilder, Polygon> {
  final List<LatLng> points;
  final List<Offset> offsets = [];
  final List<List<LatLng>>? holePointsList;
  final List<List<Offset>>? holeOffsetsList;
  late final LatLngBounds boundingBox;

  Polygon({
    dynamic id,
    required PolygonBuilder builder,
    required this.points,
    this.holePointsList,
    PolygonCallback? onTap,
    PolygonCallback? onDrag,
  })  : holeOffsetsList = null == holePointsList || holePointsList.isEmpty
            ? null
            : List.generate(holePointsList.length, (_) => []),
        super(
            builder: builder,
            id: id,
            onDrag: onDrag,
            onTap: onTap,
            delta: LatLng(0,0),
            zIndex: 0);


  Polygon copyWithNewPoint(LatLng point) {
    final oldCenter = LatLngHelper.centerOfListOfPoints(points);
    final delta = oldCenter.difference(point);
    final newPoints = points.map((e) {
      return e.add(
        delta,
      );
    }).toList();
    return Polygon(
      points: newPoints,
      holePointsList: holePointsList,
      id: id,
      builder: builder,
      onDrag: onDrag,
      onTap: onTap,
    );
  }

  @override
  Polygon copyWithNewDelta(LatLng location) {
    // TODO: implement copyWithNewDelta
    throw UnimplementedError();
  }
}

class PolygonLayerWidget extends StatelessWidget {
  final PolygonLayerOptions options;
  PolygonLayerWidget({Key? key, required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return PolygonLayer(
      options,
      mapState,
      mapState.onMoved,
    );
  }
}

class PolygonLayer extends StatefulWidget {
  final PolygonLayerOptions polygonOpts;
  final MapState map;
  final Stream<Null>? stream;

  PolygonLayer(this.polygonOpts, this.map, this.stream)
      : super(key: polygonOpts.key);

  @override
  State<PolygonLayer> createState() => _PolygonLayerState();
}

class _PolygonLayerState extends State<PolygonLayer> {
  Polygon? _draggingPolygon;
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

          if (null != polygon.holeOffsetsList) {
            for (var offsets in polygon.holeOffsetsList!) {
              offsets.clear();
            }
          }

          if (widget.polygonOpts.polygonCulling &&
              !polygon.boundingBox.isOverlapping(widget.map.bounds)) {
            // skip this polygon as it's offscreen
            continue;
          }

          _fillOffsets(polygon.offsets, polygon.points);

          if (null != polygon.holePointsList) {
            for (var i = 0, len = polygon.holePointsList!.length;
                i < len;
                ++i) {
              _fillOffsets(
                  polygon.holeOffsetsList![i], polygon.holePointsList![i]);
            }
          }

          polygons.add(
            SizedBox.fromSize(
              size: size,
              child: polygon.builder(
                context,
                polygon.points,
                polygon.offsets,
                polygon.holePointsList,
                polygon.holeOffsetsList,
              ),
            ),
          );
        }

        return Listener(
          onPointerMove: (details) {
                  if (_draggingPolygon != null &&
                      _draggingPolygon!.onDrag != null) {
                    final location = widget.map.offsetToLatLng(
                      details.localPosition,
                      context.size!.width,
                      context.size!.height,
                    );

                    widget.polygonOpts.polygons.remove(_draggingPolygon!);
                    _draggingPolygon =
                        _draggingPolygon!.copyWithNewPoint(location);
                    widget.polygonOpts.polygons.add(_draggingPolygon!);

                    _draggingPolygon!.onDrag?.call(_draggingPolygon!);
                    setState(() {});
                  }
                },
          onPointerUp: (_) {
            setState(() {
              //widget.polygonOpts.handlingTouch = false;
              _draggingPolygon = null;
            });
          },
          child: PolygonGestureDetector(
            mapState: widget.map,
            polygons: widget.polygonOpts.polygons,
            onTapDownOnPolygon: (polygon) {
              setState(() {
                //widget.polygonOpts.handlingTouch = true;
                _draggingPolygon = polygon;
              });
            },
            onTapOnPolygon: (polygon) {
              polygon.onTap?.call(polygon);
            },
            child: Stack(
              children: polygons,
            ),
          ),
        );
      },
    );
  }

  void _fillOffsets(final List<Offset> offsets, final List<LatLng> points) {
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
  }
}

class PolygonGestureDetector extends StatefulWidget {
  final List<Polygon> polygons;
  final MapState mapState;
  final Widget child;
  final Function(Polygon) onTapDownOnPolygon;
  final Function(Polygon) onTapOnPolygon;
  const PolygonGestureDetector({
    Key? key,
    required this.polygons,
    required this.mapState,
    required this.child,
    required this.onTapDownOnPolygon,
    required this.onTapOnPolygon,
  }) : super(key: key);

  @override
  State<PolygonGestureDetector> createState() => _PolygonGestureDetectorState();
}

class _PolygonGestureDetectorState extends State<PolygonGestureDetector> {
  Offset? _lastOffset;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: widget.child,
      onTapDown: (details) {
        final p = _tapped(details.localPosition, context);
        if (p != null) {
          widget.onTapDownOnPolygon(p);
          _lastOffset = details.localPosition;
        } else {
          _lastOffset = null;
        }
      },
      onTapUp: (details) {
        if (_lastOffset == details.localPosition) {
          final p = _tapped(details.localPosition, context);
          if (p != null) {
            widget.onTapOnPolygon(p);
          }
        }
      },
    );
  }

  Polygon? _tapped(Offset offset, BuildContext context) {
    final location = widget.mapState.offsetToLatLng(
      offset,
      context.size!.width,
      context.size!.height,
    );
    for (var p in widget.polygons) {
      if ((p.onDrag != null || p.onTap != null) &&
          PolygonUtil.containsLocation(location, p.points, true)) {
        return p;
      }
    }
    return null;
  }
}

typedef PolygonBuilder = Widget Function(
  BuildContext context,
  List<LatLng> points,
  List<Offset> offsets,
  List<List<LatLng>>? holePointsList,
  List<List<Offset>>? holeOffsetsList,
);

class PolygonWidget extends StatefulWidget {
  final Color borderColor, color;
  final double borderStrokeWidth;
  final bool dottedBorder, disableHolesBorder;
  final List<LatLng> points;
  final List<Offset> offsets;
  final List<List<LatLng>>? holePointsList;
  final List<List<Offset>>? holeOffsetsList;
  PolygonWidget({
    Key? key,
    required this.points,
    required this.offsets,
    required this.holePointsList,
    required this.holeOffsetsList,
    this.borderColor = Colors.black,
    this.color = Colors.blue,
    this.borderStrokeWidth = 1.0,
    this.dottedBorder = false,
    this.disableHolesBorder = true,
  }) : super(key: key);

  @override
  State<PolygonWidget> createState() => _PolygonWidgetState();
}

class _PolygonWidgetState extends State<PolygonWidget> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PolygonPainter(
        borderColor: widget.borderColor,
        color: widget.color,
        borderStrokeWidth: widget.borderStrokeWidth,
        dottedBorder: widget.dottedBorder,
        holeOffsetsList: widget.holeOffsetsList,
        holePointsList: widget.holePointsList,
        disableHolesBorder: widget.disableHolesBorder,
        points: widget.points,
        offsets: widget.offsets,
      ),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final Color borderColor, color;
  final double borderStrokeWidth;
  final bool dottedBorder, disableHolesBorder;
  final List<LatLng> points;
  final List<Offset> offsets;
  final List<List<LatLng>>? holePointsList;
  final List<List<Offset>>? holeOffsetsList;

  PolygonPainter({
    required this.borderColor,
    required this.color,
    required this.borderStrokeWidth,
    required this.dottedBorder,
    required this.disableHolesBorder,
    required this.points,
    required this.offsets,
    required this.holePointsList,
    required this.holeOffsetsList,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (offsets.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    _paintPolygon(canvas, rect);
  }

  void _paintBorder(Canvas canvas) {
    if (borderStrokeWidth > 0.0) {
      var borderRadius = (borderStrokeWidth / 2);

      final borderPaint = Paint()
        ..color = borderColor
        ..strokeWidth = borderStrokeWidth;

      if (dottedBorder) {
        var spacing = borderStrokeWidth * 1.5;
        _paintDottedLine(canvas, offsets, borderRadius, spacing, borderPaint);

        if (disableHolesBorder && null != holeOffsetsList) {
          for (var offsets in holeOffsetsList!) {
            _paintDottedLine(
                canvas, offsets, borderRadius, spacing, borderPaint);
          }
        }
      } else {
        _paintLine(canvas, offsets, borderRadius, borderPaint);

        if (!disableHolesBorder && null != holeOffsetsList) {
          for (var offsets in holeOffsetsList!) {
            _paintLine(canvas, offsets, borderRadius, borderPaint);
          }
        }
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

  void _paintPolygon(Canvas canvas, Rect rect) {
    final paint = Paint();

    if (null != holeOffsetsList) {
      canvas.saveLayer(rect, paint);
      paint.style = PaintingStyle.fill;

      for (var offsets in holeOffsetsList!) {
        var path = Path();
        path.addPolygon(offsets, true);
        canvas.drawPath(path, paint);
      }

      paint
        ..color = color
        ..blendMode = BlendMode.srcOut;

      var path = Path();
      path.addPolygon(offsets, true);
      canvas.drawPath(path, paint);

      _paintBorder(canvas);

      canvas.restore();
    } else {
      canvas.clipRect(rect);
      paint
        ..style = PaintingStyle.fill
        ..color = color;

      var path = Path();
      path.addPolygon(offsets, true);
      canvas.drawPath(path, paint);

      _paintBorder(canvas);
    }
  }

  @override
  bool shouldRepaint(PolygonPainter other) => false;

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
