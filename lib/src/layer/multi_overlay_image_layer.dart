import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class MultiOverlayImageLayerOptions extends LayerOptions {
  final List<MultiOverlayImage> overlayImages;

  MultiOverlayImageLayerOptions({
    Key? key,
    this.overlayImages = const [],
    Stream<Null>? rebuild,
  }) : super(
          key: key,
          rebuild: rebuild,
        );
}

typedef MutiOverlayImageBuilder = Widget Function(Widget image);

class MultiOverlayImage
    extends MapElement<MutiOverlayImageBuilder, MultiOverlayImage> {
  final LatLngBounds bounds;
  final ImageProvider imageProvider;
  final double opacity;
  final bool gaplessPlayback;

  MultiOverlayImage(
      {required this.bounds,
      required this.imageProvider,
      this.opacity = 1.0,
      this.gaplessPlayback = false,
      required String id,
      required MutiOverlayImageBuilder builder,
      Null Function(MultiOverlayImage)? onTap,
      Null Function(MultiOverlayImage)? onDrag,
      int zIndex = 0,
      LatLng delta = const LatLng.zero()})
      : super(
            builder: builder,
            delta: delta,
            id: id,
            onDrag: onDrag,
            onTap: onTap,
            zIndex: zIndex);

  @override
  MultiOverlayImage copyWithNewDelta(LatLng location) {
    return MultiOverlayImage(
      bounds: copyBoundsWithDelta(location, bounds),
      imageProvider: imageProvider,
      id: id,
      builder: builder,
      delta: delta,
      gaplessPlayback: gaplessPlayback,
      onDrag: onDrag,
      onTap: onTap,
      opacity: opacity,
      zIndex: zIndex,
    );
  }

  LatLngBounds copyBoundsWithDelta(LatLng delta, LatLngBounds bounds) {
    return LatLngBounds(bounds.northEast?.add(delta, remainder: false),
        bounds.southWest?.add(delta, remainder: false));
  }

  @override
  bool containsLocation(LatLng location) {
    return bounds.contains(location);
  }
}

class MultiOverlayImageLayerWidget extends StatelessWidget {
  final MultiOverlayImageLayerOptions options;

  MultiOverlayImageLayerWidget({Key? key, required this.options})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return MultiOverlayImageLayer(options, mapState, mapState.onMoved);
  }
}

class MultiOverlayImageLayer extends StatefulWidget {
  final MultiOverlayImageLayerOptions overlayImageOpts;
  final MapState map;
  final Stream<Null>? stream;

  MultiOverlayImageLayer(this.overlayImageOpts, this.map, this.stream)
      : super(key: overlayImageOpts.key);

  @override
  State<MultiOverlayImageLayer> createState() => _MultiOverlayImageLayerState();
}

class _MultiOverlayImageLayerState extends State<MultiOverlayImageLayer> {
  MultiOverlayImage? _draggingPolygon;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: widget.stream,
      builder: (BuildContext context, _) {
        return ClipRect(
          child: FlutterMapLayerGestureListener(
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

              widget.overlayImageOpts.overlayImages.remove(_draggingPolygon);

              _draggingPolygon = _draggingPolygon!.copyWithNewDelta(delta);
              widget.overlayImageOpts.overlayImages.add(_draggingPolygon!);

              setState(() {});
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
                true,
              );
              if (tapped == null) {
                return false;
              }
              tapped.onTap!.call(tapped);
              return true;
            },
            child: Stack(
              children: _positionedForOverlay(),
            ),
          ),
        );
      },
    );
  }

  MultiOverlayImage? _tapped(Offset offset, BuildContext context, bool forTap) {
    final location = widget.map.offsetToLatLng(
      offset,
      context.size!.width,
      context.size!.height,
    );
    for (var p in widget.overlayImageOpts.overlayImages) {
      final valid = forTap ? p.onTap != null : p.onDrag != null;
      if (valid && p.containsLocation(location)) {
        if ((p.onDrag != null || p.onTap != null)) {
          return p;
        }
      }
    }
    return null;
  }

  List<Positioned> _positionedForOverlay() {
    final returnable = <Positioned>[];
    for (var overlayImage in widget.overlayImageOpts.overlayImages) {
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
          child: Image(
            image: overlayImage.imageProvider,
            fit: BoxFit.fill,
            color: Color.fromRGBO(255, 255, 255, overlayImage.opacity),
            colorBlendMode: BlendMode.modulate,
            gaplessPlayback: overlayImage.gaplessPlayback,
          ),
        ),
      );
    }
    return returnable;
  }
}
