import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class MultiPolylineLayerOptions extends LayerOptions<MultiPolyline> {
  final List<MultiPolyline> multiPolylines;
  final bool polylineCulling;

  MultiPolylineLayerOptions({
    Key? key,
    this.multiPolylines = const [],
    this.polylineCulling = false,
    Stream<Null>? rebuild,
  }) : super(
    key: key,
    rebuild: rebuild,
  ) {
    if (polylineCulling) {
      for (var polyline in multiPolylines) {
        polyline.boundingBox = LatLngBounds.fromPoints(
          [
            for (var item in polyline.points) ...item,
          ],
        );
      }
    }
  }
}

typedef void MultiPolylineCallback(marker);

typedef MultiPolylineBuilder = Widget Function(
    BuildContext context,
    List<List<LatLng>> points,
    List<List<Offset>> offsets,
    LatLngBounds? boundingBox,
    );

class MultiPolyline extends MapElement<MultiPolylineBuilder, MultiPolyline> {
  final List<List<LatLng>> points;
  final List<List<Offset>> offsets = [];
  final int tolerance;
  LatLngBounds? boundingBox;

  MultiPolyline({
    this.tolerance = 5000,
    Null Function(MultiPolyline)? onTap,
    required String id,
    required MultiPolylineBuilder builder,
    required this.points,
    int zIndex = 0,
  }) : super(
    builder: builder,
    id: id,
    onDrag: null,
    onTap: onTap,
    delta: LatLng(0,0),
    zIndex: zIndex,
  );

  @override
  MultiPolyline copyWithNewDelta(LatLng location) {
    // TODO: implement copyWithNewPoint
    throw UnimplementedError();
  }
}

class MultiPolylineLayerWidget extends StatelessWidget {
  final MultiPolylineLayerOptions options;

  MultiPolylineLayerWidget({Key? key, required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return MultiPolylineLayer(
      options,
      mapState,
      options.rebuild,
    );
  }
}

class MultiPolylineLayer extends StatefulWidget {
  final MultiPolylineLayerOptions polylineOpts;
  final MapState map;
  final Stream<Null>? stream;

  MultiPolylineLayer(this.polylineOpts, this.map, this.stream)
      : super(key: polylineOpts.key);

  @override
  State<MultiPolylineLayer> createState() => _MultiPolylineLayerState();
}

class _MultiPolylineLayerState extends State<MultiPolylineLayer> {
  // MultiPolyline? _draggingPolyline;
  // LatLng? _lastDragPoint;
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
    return StreamBuilder<void>(
      stream: widget.stream, // a Stream<void> or null
      builder: (BuildContext context, _) {
        var multiPolylines = <Widget>[];

        for (var polylineOpt in widget.polylineOpts.multiPolylines) {
          polylineOpt.offsets.clear();

          if (widget.polylineOpts.polylineCulling &&
              (polylineOpt.boundingBox?.isOverlapping(widget.map.bounds) ??
                  false)) {
            // skip this polyline as it's offscreen
            continue;
          }

          _fillOffsets(polylineOpt.offsets, polylineOpt.points);

          multiPolylines.add(
            SizedBox.fromSize(
              size: size,
              child: polylineOpt.builder(
                context,
                polylineOpt.points,
                polylineOpt.offsets,
                polylineOpt.boundingBox,
              ),
            ),
          );
        }

        return FlutterMapLayerGestureListener(
          onTap: (details) {
            final tapped = _tapped(
              details.localPosition,
              context,
              true,
            );
            if (tapped == null) {
              return false;
            }
            tapped.onTap!.call(tapped);
            return true;
          },
          child: Stack(
            children: multiPolylines,
          ),
        );
      },
    );
  }

  MapElement? _tapped(Offset offset, BuildContext context, bool forTap) {
    final location = widget.map.offsetToLatLng(
      offset,
      context.size!.width,
      context.size!.height,
    );
    MapElement? polyline;
    for (var p in widget.polylineOpts.multiPolylines) {
      final valid = forTap ? p.onTap != null : p.onDrag != null;
      if (valid &&
          p.points.any(
                (points) => PolygonUtil.isLocationOnPath(location, points, true,
                tolerance: p.tolerance * (1 / widget.map.zoom)),
          )) {
        if ((p.onDrag != null || p.onTap != null)) {
          polyline = p;
          break;
        }
      }
    }
    return polyline;
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

// MultiPolylineWidget class definition
class MultiPolylineWidget extends StatefulWidget {
  final List<List<LatLng>> points;
  final List<List<Offset>> offsets;
  final double strokeWidth;
  final Color color;
  final double borderStrokeWidth;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final List<double>? colorsStop;
  final bool isDotted;
  final LatLngBounds? boundingBox;
  final bool showAnimation;

  const MultiPolylineWidget({
    Key? key,
    required this.points,
    required this.offsets,
    required this.boundingBox,
    this.strokeWidth = 1.0,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.gradientColors,
    this.colorsStop,
    this.isDotted = false,
    this.showAnimation = false,
  }) : super(key: key);

  @override
  State<MultiPolylineWidget> createState() => _MultiPolylineWidgetState();
}

class _MultiPolylineWidgetState extends State<MultiPolylineWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);
    _rippleAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rippleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: MultiPolylinePainter(
            boundingBox: widget.boundingBox,
            allOffsets: widget.offsets,
            allPoints: widget.points,
            borderColor: widget.borderColor,
            borderStrokeWidth: widget.borderStrokeWidth,
            color: widget.color,
            colorsStop: widget.colorsStop,
            gradientColors: widget.gradientColors,
            isDotted: widget.isDotted,
            strokeWidth: widget.strokeWidth,
            showAnimation: widget.showAnimation,
            animationValue: _rippleAnimation.value,
          ),
        );
      },
    );
  }
}

class MultiPolylinePainter extends CustomPainter {
  final List<List<LatLng>> allPoints;
  final List<List<Offset>> allOffsets;
  final double strokeWidth;
  final Color color;
  final double borderStrokeWidth;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final List<double>? colorsStop;
  final bool isDotted;
  final LatLngBounds? boundingBox;
  final bool showAnimation;
  final double animationValue;

  MultiPolylinePainter({
    required this.allOffsets,
    required this.boundingBox,
    required this.allPoints,
    this.strokeWidth = 1.0,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.gradientColors,
    this.colorsStop,
    this.isDotted = false,
    required this.showAnimation,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var offsets in allOffsets) {
      if (offsets.isNotEmpty) {
        final rect = Offset.zero & size;
        canvas.clipRect(rect);
        final paint = Paint()
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.srcOver;

        if (gradientColors == null) {
          paint.color = color;
        } else {
          gradientColors!.isNotEmpty
              ? paint.shader = _paintGradient(offsets)
              : paint.color = color;
        }

        Paint? filterPaint;
        if (borderColor != null) {
          filterPaint = Paint()
            ..color = borderColor!.withAlpha(255)
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..blendMode = BlendMode.dstOut;
        }

        final borderPaint = strokeWidth > 0.0
            ? (Paint()
          ..color = borderColor ?? Color(0x00000000)
          ..strokeWidth = strokeWidth + strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.srcOver)
            : null;
        var radius = paint.strokeWidth / 2;
        var borderRadius = (borderPaint?.strokeWidth ?? 0) / 2;
        if (isDotted) {
          var spacing = strokeWidth * 1.5;
          canvas.saveLayer(rect, Paint());
          if (borderPaint != null && filterPaint != null) {
            _paintDottedLine(canvas, offsets, borderRadius, spacing, borderPaint);
            _paintDottedLine(canvas, offsets, radius, spacing, filterPaint);
          }
          _paintDottedLine(canvas, offsets, radius, spacing, paint);
          canvas.restore();
        }
        else {
          paint.style = PaintingStyle.stroke;
          canvas.saveLayer(rect, Paint());
          if (borderPaint != null && filterPaint != null) {
            borderPaint.style = PaintingStyle.stroke;
            _paintLine(canvas, offsets, borderPaint);
            filterPaint.style = PaintingStyle.stroke;
            _paintLine(canvas, offsets, filterPaint);
          }
          _paintLine(canvas, offsets, paint);
          canvas.restore();
        }
        if (showAnimation) {
          _paintBlinkLine(canvas, offsets, animationValue,);
        }
      }
    }
  }




  void _paintBlinkLine(Canvas canvas, List<Offset> offsets, double animationValue) {
    if (offsets.length < 2) return;

    // Define paint for the blinking effect
    final paint = Paint()
      ..strokeWidth = 6.0 // Adjust the stroke width as needed
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Calculate the opacity based on the animation value
    double opacity = 0.2 + animationValue * 0.8;
    opacity = opacity.clamp(0.0, 1.0);
    paint.color = Colors.amber.withOpacity(opacity);

    // Create the path for the polyline
    final path = ui.Path();
    path.moveTo(offsets[0].dx, offsets[0].dy); // Move to the first point

    for (int i = 1; i < offsets.length; i++) {
      path.lineTo(offsets[i].dx, offsets[i].dy); // Draw lines to each subsequent point
    }

    // Draw the path on the canvas
    canvas.drawPath(path, paint);
  }

  void _paintDottedLine(Canvas canvas, List<Offset> offsets, double radius,
      double stepLength, Paint paint) {
    final path = ui.Path();
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
        path.addOval(Rect.fromCircle(center: offset, radius: radius));
        distance += stepLength;
      }
      startDistance = distance < totalDistance
          ? stepLength - (totalDistance - distance)
          : distance - totalDistance;
    }
    path.addOval(Rect.fromCircle(center: offsets.last, radius: radius));
    canvas.drawPath(path, paint);
  }


  void _paintLine(Canvas canvas, List<Offset> offsets, Paint paint) {
    if (offsets.isNotEmpty) {
      final path = ui.Path()..moveTo(offsets[0].dx, offsets[0].dy);
      for (var offset in offsets) {
        path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  ui.Gradient _paintGradient(List<Offset> offsets) => ui.Gradient.linear(
      offsets.first, offsets.last, gradientColors!, _getColorsStop());

  List<double>? _getColorsStop() =>
      (colorsStop != null && colorsStop!.length == gradientColors!.length)
          ? colorsStop
          : _calculateColorsStop();

  List<double> _calculateColorsStop() {
    final colorsStopInterval = 1.0 / gradientColors!.length;
    return gradientColors!
        .map<double>((gradientColor) =>
    gradientColors!.indexOf(gradientColor) * colorsStopInterval)
        .toList();
  }


  @override
  bool shouldRepaint(covariant MultiPolylinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.showAnimation != showAnimation;
  }
}

double _dist(Offset v, Offset w) {
  return sqrt(_dist2(v, w));
}

double _dist2(Offset v, Offset w) {
  return _sqr(v.dx - w.dx) + _sqr(v.dy - w.dy);
}

double _sqr(double x) {
  return x * x;
}
