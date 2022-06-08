import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/helpers/helpers.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong2/latlong.dart';

class MarkerLayerOptions extends LayerOptions<Marker> {
  final List<Marker> markers;

  /// If true markers will be counter rotated to the map rotation
  final bool? rotate;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset? rotateOrigin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [rotateOrigin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  final AlignmentGeometry? rotateAlignment;

  MarkerLayerOptions({
    Key? key,
    this.markers = const [],
    this.rotate = false,
    this.rotateOrigin,
    this.rotateAlignment = Alignment.center,
    Stream<Null>? rebuild,
    LayerElementDragCallback? onLayerElementDrag,
  }) : super(
          key: key,
          rebuild: rebuild,
          onLayerElementDrag: onLayerElementDrag,
        );

  @override
  void handleDrag(_) {}
}

class Anchor {
  final double left;
  final double top;

  Anchor(this.left, this.top);

  Anchor._(double width, double height, AnchorAlign alignOpt)
      : left = _leftOffset(width, alignOpt),
        top = _topOffset(height, alignOpt);

  static double _leftOffset(double width, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.left:
        return 0.0;
      case AnchorAlign.right:
        return width;
      case AnchorAlign.top:
      case AnchorAlign.bottom:
      case AnchorAlign.center:
      default:
        return width / 2;
    }
  }

  static double _topOffset(double height, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.top:
        return 0.0;
      case AnchorAlign.bottom:
        return height;
      case AnchorAlign.left:
      case AnchorAlign.right:
      case AnchorAlign.center:
      default:
        return height / 2;
    }
  }

  factory Anchor.forPos(AnchorPos? pos, double width, double height) {
    if (pos == null) return Anchor._(width, height, AnchorAlign.none);
    if (pos.value is AnchorAlign) return Anchor._(width, height, pos.value);
    if (pos.value is Anchor) return pos.value;
    throw Exception('Unsupported AnchorPos value type: ${pos.runtimeType}.');
  }
}

class AnchorPos<T> {
  AnchorPos._(this.value);
  T value;
  static AnchorPos exactly(Anchor anchor) => AnchorPos._(anchor);
  static AnchorPos align(AnchorAlign alignOpt) => AnchorPos._(alignOpt);
}

enum AnchorAlign {
  none,
  left,
  right,
  top,
  bottom,
  center,
}

class Marker extends MapElement<WidgetBuilder, Marker> {
  final LatLng point;
  final double width;
  final double height;
  final Anchor anchor;

  /// If true marker will be counter rotated to the map rotation
  final bool? rotate;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset? rotateOrigin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [rotateOrigin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  final AlignmentGeometry? rotateAlignment;

  Marker({
    required this.point,
    required WidgetBuilder builder,
    required String id,
    this.width = 30.0,
    this.height = 30.0,
    this.rotate,
    this.rotateOrigin,
    this.rotateAlignment,
    AnchorPos? anchorPos,
<<<<<<< HEAD
    MapElementCallback? onTap,
    MapElementCallback? onDrag,
=======
    LocationCallaback? onTap,
    LocationCallaback? onDrag,
>>>>>>> 61b6beddf6a370f9c4e0e44ea01256fba2088583
  })  : anchor = Anchor.forPos(anchorPos, width, height),
        super(
          id: id,
          builder: builder,
          onDrag: onDrag,
          onTap: onTap,
        );
  @override
  Marker copyWithNewDelta(LatLng point) {
    return Marker(
      point: point,
      builder: builder,
      width: width,
      height: height,
      rotate: rotate,
      rotateAlignment: rotateAlignment,
      rotateOrigin: rotateOrigin,
      id: id,
    );
  }
}

class MarkerLayerWidget extends StatelessWidget {
  final MarkerLayerOptions options;

  MarkerLayerWidget({Key? key, required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return MarkerLayer(
      options,
      mapState,
      mapState.onMoved,
    );
  }
}

class MarkerLayer extends StatefulWidget {
  final MarkerLayerOptions markerLayerOptions;
  final MapState map;
  final Stream<Null>? stream;

  MarkerLayer(this.markerLayerOptions, this.map, this.stream)
      : super(key: markerLayerOptions.key);

  @override
  _MarkerLayerState createState() => _MarkerLayerState();
}

class _MarkerLayerState extends State<MarkerLayer> {
  Marker? _draggingMarker;
  var lastZoom = -1.0;

  /// List containing cached pixel positions of markers
  /// Should be discarded when zoom changes
  // Has a fixed length of markerOpts.markers.length - better performance:
  // https://stackoverflow.com/questions/15943890/is-there-a-performance-benefit-in-using-fixed-length-lists-in-dart
  var _pxCache = <CustomPoint>[];

  // Calling this every time markerOpts change should guarantee proper length
  List<CustomPoint> generatePxCache() => List.generate(
        widget.markerLayerOptions.markers.length,
        (i) => widget.map.project(
          widget.markerLayerOptions.markers[i].point,
        ),
      );

  @override
  void initState() {
    super.initState();
    _pxCache = generatePxCache();

    //print(_draggingMarker?.id);
  }

  @override
  void didUpdateWidget(covariant MarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    lastZoom = -1.0;
    _pxCache = generatePxCache();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: widget.stream, // a Stream<int> or null
      builder: (BuildContext context, AsyncSnapshot<int?> snapshot) {
        var markers = <Widget>[];
        final sameZoom = widget.map.zoom == lastZoom;
        for (var i = 0; i < widget.markerLayerOptions.markers.length; i++) {
          var marker = widget.markerLayerOptions.markers[i];

          // Decide whether to use cached point or calculate it
          var pxPoint =
              sameZoom ? _pxCache[i] : widget.map.project(marker.point);
          if (!sameZoom) {
            _pxCache[i] = pxPoint;
          }

          final width = marker.width - marker.anchor.left;
          final height = marker.height - marker.anchor.top;
          var sw = CustomPoint(pxPoint.x + width, pxPoint.y - height);
          var ne = CustomPoint(pxPoint.x - width, pxPoint.y + height);

          if (!widget.map.pixelBounds.containsPartialBounds(Bounds(sw, ne))) {
            continue;
          }

          final pos = pxPoint - widget.map.getPixelOrigin();
          final markerWidget =
              (marker.rotate ?? widget.markerLayerOptions.rotate ?? false)
                  // Counter rotated marker to the map rotation
                  ? Transform.rotate(
                      angle: -widget.map.rotationRad,
                      origin: marker.rotateOrigin ??
                          widget.markerLayerOptions.rotateOrigin,
                      alignment: marker.rotateAlignment ??
                          widget.markerLayerOptions.rotateAlignment,
                      child: marker.builder(context),
                    )
                  : marker.builder(context);

          markers.add(
            Positioned(
              key: ValueKey(marker.id),
              width: marker.width,
              height: marker.height,
              left: pos.x - width,
              top: pos.y - height,
              child: GestureDetector(
                onTapDown: (deets) {
                  setState(() {
                    widget.markerLayerOptions.handlingTouch = true;
                    _draggingMarker = marker;
                  });
                },
                onTap: () {
<<<<<<< HEAD
                  marker.onTap?.call(marker);
=======
                  marker.onTap?.call(marker.point);
>>>>>>> 61b6beddf6a370f9c4e0e44ea01256fba2088583
                },
                child: Container(
                  color: marker == _draggingMarker ? Colors.blueGrey : null,
                  child: markerWidget,
                ),
              ),
            ),
          );
        }
        lastZoom = widget.map.zoom;
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: widget.markerLayerOptions.handlingTouch
              ? (details) {
                  if (_draggingMarker != null) {
                    final location = widget.map.offsetToLatLng(
                      details.localPosition,
                      context.size!.width,
                      context.size!.height,
                    );

                    widget.markerLayerOptions.markers.remove(_draggingMarker!);
                    _draggingMarker =
                        _draggingMarker!.copyWithNewDelta(location);
                    widget.markerLayerOptions.markers.add(_draggingMarker!);

                    _draggingMarker!.onDrag?.call(_draggingMarker!);
                    setState(() => _pxCache = generatePxCache());
                  }
                }
              : null,
          onPointerUp: (_) {
            setState(() {
              widget.markerLayerOptions.handlingTouch = false;
              _draggingMarker = null;
            });
          },
          child: Container(
            child: Stack(
              children: markers,
            ),
          ),
        );
      },
    );
  }
}
