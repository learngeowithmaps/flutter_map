import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/helpers/map_toolkit.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong2/latlong.dart' hide Path; // conflict with Path from UI
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

typedef MultiPolygonCallback = void Function(MultiPolygon);

class MultiPolygon extends MapElement<MultiPolygonBuilder, MultiPolygon> {
  final List<List<LatLng>> points;
  final List<List<Offset>> offsets = [];
  late final LatLngBounds boundingBox;

  MultiPolygon({
    required String id,
    required MultiPolygonBuilder builder,
    required this.points,
    MultiPolygonCallback? onTap,
    MultiPolygonCallback? onDrag,
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
    return MultiPolygonLayer(options, mapState, mapState.onMoved);
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
  LatLng? _lastDragPoint;
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

        return Listener(
          onPointerMove: widget.polygonOpts.handlingTouch
              ? (details) {
                  if (_draggingPolygon != null &&
                      _draggingPolygon!.onDrag != null) {
                    final location = widget.map.offsetToLatLng(
                      details.localPosition,
                      context.size!.width,
                      context.size!.height,
                    );

                    final delta = _lastDragPoint!.difference(location);
                    _lastDragPoint = location;

                    widget.polygonOpts.polygons.remove(_draggingPolygon!);

                    _draggingPolygon =
                        _draggingPolygon!.copyWithNewDelta(delta);
                    widget.polygonOpts.polygons.add(_draggingPolygon!);

                    _draggingPolygon!.onDrag?.call(_draggingPolygon!);
                    setState(() {});
                  }
                }
              : null,
          onPointerUp: (_) {
            setState(() {
              widget.polygonOpts.handlingTouch = false;
              _draggingPolygon = null;
              _lastDragPoint = null;
            });
          },
          child: MultiPolygonGestureDetector(
            mapState: widget.map,
            polygons: widget.polygonOpts.polygons,
            onTapDownOnPolygon: (polygon, details) {
              setState(() {
                widget.polygonOpts.handlingTouch = true;
                _draggingPolygon = polygon;
                _lastDragPoint = widget.map.offsetToLatLng(
                  details.localPosition,
                  context.size!.width,
                  context.size!.height,
                );
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

class MultiPolygonGestureDetector extends StatefulWidget {
  final List<MultiPolygon> polygons;
  final MapState mapState;
  final Widget child;
  final Function(MultiPolygon, TapDownDetails) onTapDownOnPolygon;
  final Function(MultiPolygon) onTapOnPolygon;
  const MultiPolygonGestureDetector({
    Key? key,
    required this.polygons,
    required this.mapState,
    required this.child,
    required this.onTapDownOnPolygon,
    required this.onTapOnPolygon,
  }) : super(key: key);

  @override
  State<MultiPolygonGestureDetector> createState() =>
      _MultiPolygonGestureDetectorState();
}

class _MultiPolygonGestureDetectorState
    extends State<MultiPolygonGestureDetector> {
  Offset? _lastOffset;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: widget.child,
      onTapDown: (details) {
        final p = _tapped(details.localPosition, context);
        if (p != null) {
          widget.onTapDownOnPolygon(p, details);
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

  MultiPolygon? _tapped(Offset offset, BuildContext context) {
    final location = widget.mapState.offsetToLatLng(
      offset,
      context.size!.width,
      context.size!.height,
    );
    for (var p in widget.polygons) {
      if (p.onTap != null &&
          p.points.any((points) =>
              PolygonUtil.containsLocation(location, points, true))) {
        return p;
      }
    }
    return null;
  }
}

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
