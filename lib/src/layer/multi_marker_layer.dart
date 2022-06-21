import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/helpers/gesture.dart';
import 'package:flutter_map/src/helpers/helpers.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong2/latlong.dart';

import '../../plugin_api.dart';

class MultiMarkerLayerOptions extends LayerOptions<MultiMarker> {
  final List<MultiMarker> multiMarkers;

  /// If true multiMarkers will be counter rotated to the map rotation
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

  MultiMarkerLayerOptions({
    Key? key,
    this.multiMarkers = const [],
    this.rotate = false,
    this.rotateOrigin,
    this.rotateAlignment = Alignment.center,
    Stream<Null>? rebuild,
    LayerElementDragCallback? onLayerElementDrag,
  }) : super(
          key: key,
          rebuild: rebuild,
        );

  @override
  void handleDrag(_) {}
}

typedef MultiMarkerCallback = void Function(MultiMarker);

class MultiMarker extends MapElement<WidgetBuilder, MultiMarker> {
  final List<LatLng> points;
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

  MultiMarker({
    required this.points,
    required WidgetBuilder builder,
    required String id,
    this.width = 30.0,
    this.height = 30.0,
    this.rotate,
    this.rotateOrigin,
    this.rotateAlignment,
    AnchorPos? anchorPos,
    VoidCallback? onTap,
    VoidCallback? onDrag,
  })  : anchor = Anchor.forPos(anchorPos, width, height),
        super(
          id: id,
          builder: builder,
          onDrag: onDrag,
          onTap: onTap,
        );

  CustomPoint sw(CustomPoint pxPoint) => CustomPoint(
      pxPoint.x + (width - anchor.left), pxPoint.y - (height - anchor.top));
  CustomPoint ne(CustomPoint pxPoint) => CustomPoint(
      pxPoint.x - (width - anchor.left), pxPoint.y + (height - anchor.top));

  @override
  MultiMarker copyWithNewDelta(LatLng point) {
    return MultiMarker(
      points: points.map((e) => e.add(point)).toList(),
      builder: builder,
      width: width,
      height: height,
      rotate: rotate,
      rotateAlignment: rotateAlignment,
      rotateOrigin: rotateOrigin,
      id: id,
      onDrag: onDrag,
      onTap: onTap,
    );
  }
}

class MultiMarkerLayerWidget extends StatelessWidget {
  final MultiMarkerLayerOptions options;

  MultiMarkerLayerWidget({Key? key, required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return MultiMarkerLayer(
      options,
      mapState,
      mapState.onMoved,
    );
  }
}

class MultiMarkerLayer extends StatefulWidget {
  final MultiMarkerLayerOptions markerLayerOptions;
  final MapState map;
  final Stream<Null>? stream;

  MultiMarkerLayer(this.markerLayerOptions, this.map, this.stream)
      : super(key: markerLayerOptions.key);

  @override
  _MultiMarkerLayerState createState() => _MultiMarkerLayerState();
}

class _MultiMarkerLayerState extends State<MultiMarkerLayer> {
  MultiMarker? _draggingMultiMarker;
  var lastZoom = -1.0;
  LatLng? _lastDragPoint;

  /// List containing cached pixel positions of multiMarkers
  /// Should be discarded when zoom changes
  // Has a fixed length of markerOpts.multiMarkers.length - better performance:
  // https://stackoverflow.com/questions/15943890/is-there-a-performance-benefit-in-using-fixed-length-lists-in-dart
  Map<MultiMarker, List<CustomPoint>> _pxCache = {};
  Map<MultiMarker, List<List<LatLng>>> _boundsCache = {};

  // Calling this every time markerOpts change should guarantee proper length
  void generatePxCache([MultiMarker? multiMarker]) {
    final genBounds =
        (MultiMarker multiMarker, List<CustomPoint<num>> pxPoints) {
      final width = multiMarker.width - multiMarker.anchor.left;
      final height = multiMarker.height - multiMarker.anchor.top;
      return pxPoints.map((pxPoint) {
        var sw = CustomPoint(pxPoint.x + width, pxPoint.y - height);
        var ne = CustomPoint(pxPoint.x - width, pxPoint.y + height);
        final swll = widget.map.unproject(sw);
        final nell = widget.map.unproject(ne);
        return [
          swll,
          LatLng(
            nell.latitude,
            swll.longitude,
          ),
          nell,
          LatLng(
            swll.latitude,
            nell.longitude,
          ),
          swll,
        ];
      }).toList();
    };
    if (multiMarker != null) {
      final pxPoints = _pxCache.update(multiMarker,
          (value) => multiMarker.points.map(widget.map.project).toList(),
          ifAbsent: () => multiMarker.points.map(widget.map.project).toList());

      _boundsCache.update(
        multiMarker,
        (_) {
          return genBounds(multiMarker, pxPoints);
        },
        ifAbsent: () {
          return genBounds(multiMarker, pxPoints);
        },
      );
    } else {
      _pxCache = Map.fromEntries(widget.markerLayerOptions.multiMarkers
          .map((i) => MapEntry(i, i.points.map(widget.map.project).toList())));
      _boundsCache = _pxCache.map((multiMarker, pxCache) =>
          MapEntry(multiMarker, genBounds(multiMarker, pxCache)));
    }
  }

  @override
  void initState() {
    super.initState();
    generatePxCache();

    //print(_draggingMultiMarker?.id);
  }

  @override
  void didUpdateWidget(covariant MultiMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    lastZoom = -1.0;
    generatePxCache();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: widget.stream, // a Stream<int> or null
      builder: (BuildContext context, AsyncSnapshot<int?> snapshot) {
        var multiMarkers = <Widget>[];
        final sameZoom = widget.map.zoom == lastZoom;
        for (var marker in widget.markerLayerOptions.multiMarkers) {
          for (var j = 0; j < marker.points.length; j++) {
            // Decide whether to use cached point or calculate it
            final useCache = _draggingMultiMarker == marker ? false : sameZoom;
            var pxPoint = useCache
                ? _pxCache[marker]![j]
                : widget.map.project(marker.points[j]);
            if (!useCache) {
              _pxCache[marker]![j] = pxPoint;
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

            multiMarkers.add(
              Positioned(
                key: ValueKey(marker.id + marker.points[j].toSexagesimal()),
                width: marker.width,
                height: marker.height,
                left: pos.x - width,
                top: pos.y - height,
                child: Container(
                  color:
                      marker == _draggingMultiMarker ? Colors.blueGrey : null,
                  child: markerWidget,
                ),
              ),
            );
          }
        }
        lastZoom = widget.map.zoom;
        return FlutterMapLayerGestureListener(
          onDragStart: (details) {
            _draggingMultiMarker = _tapped(
              details.localFocalPoint,
              context,
              false,
            );

            if (_draggingMultiMarker == null) {
              return false;
            } else {
              setState(() {});
              return true;
            }
          },
          onDragUpdate: (details) {
            if (_draggingMultiMarker == null) {
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

            final done = widget.markerLayerOptions.multiMarkers
                .remove(_draggingMultiMarker!);
            _draggingMultiMarker =
                _draggingMultiMarker!.copyWithNewDelta(delta);
            widget.markerLayerOptions.multiMarkers.add(_draggingMultiMarker!);

            _draggingMultiMarker!.onDrag?.call();
            setState(generatePxCache);
            return true;
          },
          onDragEnd: (details) {
            if (_draggingMultiMarker == null) {
              return false;
            } else {
              setState(() {
                _draggingMultiMarker = null;
              });
              return true;
            }
          },
          onTap: (details) {
            final tapped = _tapped(
              details.localPosition,
              context,
              true,
            );
            if (tapped == null) {
              return false;
            } else {
              tapped.onTap!.call();
              return true;
            }
          },
          child: Container(
            child: Stack(
              children: multiMarkers,
            ),
          ),
        );
      },
    );
  }

  MultiMarker? _tapped(Offset offset, BuildContext context, bool forTap) {
    final location = widget.map.offsetToLatLng(
      offset,
      context.size!.width,
      context.size!.height,
    );
    for (var marker in _boundsCache.keys) {
      final valid = forTap ? marker.onTap != null : marker.onDrag != null;
      final allBounds = _boundsCache[marker]!;
      for (var bounds in allBounds) {
        if (valid && PolygonUtil.containsLocation(location, bounds, true)) {
          return marker;
        }
      }
    }
    return null;
  }
}
