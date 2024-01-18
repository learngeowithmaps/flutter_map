import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart' hide Path; // conflict with Path from UI

class AllElementsLayerOptions extends LayerOptions<MultiPolygon> {
  final List<MultiPolygon> multiPolygons;
  final List<MultiPolyline> multiPolylines;
  final List<MultiMarker> multiMarkers;
  final bool polygonCulling;

  /// If true multiMarkers will be counter rotated to the map rotation
  final bool? rotate;

  final Offset? rotateOrigin;
  final AlignmentGeometry? rotateAlignment;
  final bool polylineCulling;
  final List<MultiOverlayImage> multiOverlayImages;

  AllElementsLayerOptions({
    Key? key,
    this.multiPolygons = const [],
    this.multiPolylines = const [],
    required this.multiOverlayImages,
    this.polylineCulling = false,
    this.polygonCulling = false,

    ///
    this.multiMarkers = const [],
    this.rotate = false,
    this.rotateOrigin,
    this.rotateAlignment = Alignment.center,
    Stream<Null>? rebuild,
  }) : super(
          key: key,
          rebuild: rebuild,
        ) {
    if (polygonCulling) {
      for (var polygon in multiPolygons) {
        polygon.boundingBox = LatLngBounds.fromPoints(
          [
            for (var item in polygon.points) ...item,
          ],
        );
      }
    }
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

class AllElementsLayerWidget extends StatelessWidget {
  final AllElementsLayerOptions options;
  AllElementsLayerWidget({Key? key, required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return AllElementsLayer(
      options,
      mapState,
      options.rebuild,
    );
  }
}

class AllElementsLayer extends StatefulWidget {
  final AllElementsLayerOptions options;
  final MapState map;
  final Stream<Null>? stream;

  AllElementsLayer(this.options, this.map, this.stream)
      : super(key: options.key);

  @override
  State<AllElementsLayer> createState() => _AllElementsLayerState();
}

class _AllElementsLayerState extends State<AllElementsLayer> {
  MapElement? _draggingMapElement;
  var lastZoom = -1.0;

  Map<MultiMarker, List<CustomPoint>> _pxCache = {};
  Map<MultiMarker, List<List<LatLng>>> _boundsCache = {};
  //

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
      _pxCache = Map.fromEntries(widget.options.multiMarkers
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
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    lastZoom = -1.0;
    generatePxCache();
  }

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

        for (var polygon in widget.options.multiPolygons) {
          polygon.offsets.clear();

          if (widget.options.polygonCulling &&
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

        var multiMarkers = <Widget>[];
        final sameZoom = widget.map.zoom == lastZoom;
        for (var marker in widget.options.multiMarkers) {
              final isVisible = (marker.maxZoomVisibility) <= widget.map.zoom;
      if(isVisible){
        for (var j = 0; j < marker.points.length; j++) {
          // Decide whether to use cached point or calculate it
          final useCache =
          marker.equals(_draggingMapElement) ? false : sameZoom;
          if (!_pxCache.containsKey(marker) || !useCache) {
            generatePxCache(marker);
          }
          var pxPoint = _pxCache[marker]![j];

          final width = marker.width - marker.anchor.left;
          final height = marker.height - marker.anchor.top;
          var sw = CustomPoint(pxPoint.x + width, pxPoint.y - height);
          var ne = CustomPoint(pxPoint.x - width, pxPoint.y + height);

          if (!widget.map.pixelBounds.containsPartialBounds(Bounds(sw, ne))) {
            continue;
          }

          final pos = pxPoint - widget.map.getPixelOrigin();
          final markerWidget = (marker.rotate ??
              widget.options.rotate ??
              false)
          // Counter rotated marker to the map rotation
              ? Transform.rotate(
            angle: -widget.map.rotationRad,
            origin: marker.rotateOrigin ?? widget.options.rotateOrigin,
            alignment: marker.rotateAlignment ??
                widget.options.rotateAlignment,
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
                child: markerWidget,
              ),
            ),
          );
        }
      }
         
        }
        lastZoom = widget.map.zoom;

        //polylines

        var multiPolylines = <Widget>[];

        for (var polylineOpt in widget.options.multiPolylines) {
          polylineOpt.offsets.clear();

          if (widget.options.polylineCulling &&
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

        /* return FlutterMapLayerGestureListener(
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
        ); */
        return FlutterMapLayerGestureListener(
          onDragStart: (details) {
            _draggingMapElement = _tapped(
              details.localFocalPoint,
              context,
              false,
            );
            if (_draggingMapElement == null) {
              return false;
            }
            setState(() {});
            return true;
          },
          onDragUpdate: (details) {
            if (_draggingMapElement == null) {
              return false;
            }
            if (_draggingMapElement is MultiPolygon) {
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

              widget.options.multiPolygons.remove(_draggingMapElement);

              _draggingMapElement =
                  _draggingMapElement!.copyWithNewDelta(delta);
              widget.options.multiPolygons
                  .add(_draggingMapElement! as MultiPolygon);

              setState(() {});
              return true;
            }
            if (_draggingMapElement is MultiMarker) {
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

              // final done = widget.options.multiMarkers.remove(_draggingMapElement!);
              _draggingMapElement =
                  _draggingMapElement!.copyWithNewDelta(delta);
              widget.options.multiMarkers
                  .add(_draggingMapElement! as MultiMarker);
              generatePxCache();
              widget.options.doLayerRebuild();
              return true;
            }
            if (_draggingMapElement is MultiOverlayImage) {
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

              // final done = widget.options.multiOverlayImages.remove(_draggingMapElement!);
              _draggingMapElement = _draggingMapElement!.copyWithNewDelta(delta);
              widget.options.multiOverlayImages
                  .add(_draggingMapElement! as MultiOverlayImage);
              //generatePxCache();
              //widget.options.doLayerRebuild();
              setState(() {});
              return true;
            }
            return false;
          },
          onDragEnd: (details) {
            if (_draggingMapElement == null) {
              return false;
            }
            final e = _draggingMapElement as dynamic;
            if (e is MultiMarker) {
              e.onDrag!.call(e);
            } else if (e is MultiPolygon) {
              e.onDrag!.call(e);
            }
            setState(() {
              _draggingMapElement = null;
            });
            return true;
          },
          onTap: (details) {
            final tapped = _tapped(
              details.localPosition,
              context,
              true,
            );
            if (tapped == null) {
              return false;
            }
            final e = tapped as dynamic;
            if (e is MultiMarker) {
              e.onTap!.call(e);
            } else if (e is MultiPolygon) {
              e.onTap!.call(e);
            } else if (e is MultiPolyline) {
              e.onTap!.call(e);
            }
            return true;
          },
          child: Stack(
            children: [
              ..._positionedForOverlay(),
              ...polygons,
              ...multiPolylines,
              ...multiMarkers,
            ],
          ),
        );
      },
    );
  }

  List<Widget> _positionedForOverlay() {
    final returnable = <Widget>[];
    for (var overlayImage in widget.options.multiOverlayImages) {
      final zoomScale = widget.map.getZoomScale(
          widget.map.zoom, widget.map.zoom); // TODO replace with 1?
      final pixelOrigin = widget.map.getPixelOrigin();
      final upperLeftPixel = widget.map
              .project(overlayImage.bounds.northWest)
              .multiplyBy(zoomScale) -
          pixelOrigin;
      final bottomRightPixel = widget.map
              .project(overlayImage.bounds.southEast)
              .multiplyBy(zoomScale) -
          pixelOrigin;
      returnable.add(
        Positioned(
          left: upperLeftPixel.x.toDouble(),
          top: upperLeftPixel.y.toDouble(),
          width: (bottomRightPixel.x - upperLeftPixel.x).toDouble(),
          height: (bottomRightPixel.y - upperLeftPixel.y).toDouble(),
          child: overlayImage.builder(
            Image(
              image: overlayImage.imageProvider,
              fit: BoxFit.fill,
              color: Color.fromRGBO(255, 255, 255, overlayImage.opacity),
              colorBlendMode: BlendMode.modulate,
              gaplessPlayback: overlayImage.gaplessPlayback,
            ),
          ),
        ),
      );
    }
    return returnable;
  }

  MapElement? _tapped(Offset offset, BuildContext context, bool forTap) {
    final location = widget.map.offsetToLatLng(
      offset,
      context.size!.width,
      context.size!.height,
    );

    var all = <MapElement>[];
    for (var p in widget.options.multiPolygons) {
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
          all.add(p);
        }
      }
    }
    for (var p in widget.options.multiPolylines) {
      final valid = forTap ? p.onTap != null : p.onDrag != null;
      if (valid &&
          p.points.any(
            (points) => PolygonUtil.isLocationOnPath(location, points, true,
                tolerance: p.tolerance * (1 / widget.map.zoom)),
          )) {
        if ((p.onDrag != null || p.onTap != null)) {
          all.add(p);
        }
      }
    }
    for (var m in widget.options.multiMarkers) {
      final valid = forTap ? m.onTap != null : m.onDrag != null;
      final allBounds = _boundsCache[m]!;
      for (var bounds in allBounds) {
        if (valid && PolygonUtil.containsLocation(location, bounds, true)) {
          all.add(m);
        }
      }
    }

    for (var p in widget.options.multiOverlayImages) {
      final valid = forTap ? p.onTap != null : p.onDrag != null;
      if (valid && p.containsLocation(location)) {
        if ((p.onDrag != null || p.onTap != null)) {
          all.add(p);
        }
      }
    }
    if (all.isNotEmpty) {
      if (all.length == 1) {
        return all.first;
      } else {
        all.sort((a, b) => a.zIndex - b.zIndex);
        return all.last;
      }
    } else {
      return null;
    }
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