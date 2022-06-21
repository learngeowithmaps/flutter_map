import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/gestures.dart';
import 'package:flutter_map/src/helpers/gesture.dart';
import 'package:flutter_map/src/layer/group_layer.dart';
import 'package:flutter_map/src/layer/overlay_image_layer.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:flutter_map/src/map/map_state_widget.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';

class FlutterMapState extends MapGestureMixin {
  final MapControllerImpl mapController;
  final List<StreamGroup<Null>> groups = <StreamGroup<Null>>[];
  final _positionedTapController = PositionedTapController();

  @override
  MapOptions get options => widget.options;

  @override
  late final MapState mapState;

  FlutterMapState(MapController? mapController)
      : mapController = mapController as MapControllerImpl? ??
            MapController() as MapControllerImpl;

  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    mapState.options = options;
  }

  @override
  void initState() {
    super.initState();
    mapState = MapState(
      options,
      (degree) {
        if (mounted) setState(() => {});
      },
      mapController.mapEventSink,
      widget.layers,
    );
    mapController.state = mapState;

    // Callback onMapCreated if not null
    if (options.onMapCreated != null) {
      options.onMapCreated!(mapController);
    }
  }

  void _disposeStreamGroups() {
    for (var group in groups) {
      group.close();
    }

    groups.clear();
  }

  @override
  void dispose() {
    _disposeStreamGroups();
    mapState.dispose();
    mapController.dispose();

    super.dispose();
  }

  Stream<Null> _merge(LayerOptions options) {
    if (options.rebuild == null) return mapState.onMoved;

    var group = StreamGroup<Null>();
    group.add(mapState.onMoved);
    group.add(options.rebuild!);
    groups.add(group);
    return group.stream;
  }

  @override
  Widget build(BuildContext context) {
    _disposeStreamGroups();
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      mapState.setOriginalSize(constraints.maxWidth, constraints.maxHeight);
      var size = mapState.size;

      return MapStateInheritedWidget(
        mapState: mapState,
        child: FlutterMapMasterGestureDetector(
          onLongPress: (event) {
            handleLongPress(TapPosition(
              event.globalPosition,
              event.localPosition,
            ));
          },
          onDoubleTap: (event) {
            handleDoubleTap(TapPosition(
              event.globalPosition,
              event.localPosition,
            ));
          },
          onScaleStart: handleScaleStart,
          onScaleUpdate: handleScaleUpdate,
          onScaleEnd: handleScaleEnd,
          onTap: (event) {
            handleTap(TapPosition(
              event.globalPosition,
              event.localPosition,
            ));
          },
          onTapDown: (event) {
            savePointer();
          },
          onTapUp: (event) {
            handleOnTapUp(event);
            removePointer();
          },
          onTapCancel: removePointer,
          child: ClipRect(
            child: Stack(
              children: [
                OverflowBox(
                  minWidth: size.x as double?,
                  maxWidth: size.x as double?,
                  minHeight: size.y as double?,
                  maxHeight: size.y as double?,
                  child: Transform.rotate(
                    angle: mapState.rotationRad,
                    child: Stack(
                      children: [
                        if (widget.children.isNotEmpty) ...widget.children,
                        if (widget.layers.isNotEmpty)
                          ...widget.layers.map(
                            (layer) => _createLayer(layer, options.plugins),
                          )
                      ],
                    ),
                  ),
                ),
                Stack(
                  children: [
                    if (widget.nonRotatedChildren.isNotEmpty)
                      ...widget.nonRotatedChildren,
                    if (widget.nonRotatedLayers.isNotEmpty)
                      ...widget.nonRotatedLayers.map(
                        (layer) => _createLayer(layer, options.plugins),
                      )
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _createLayer(LayerOptions options, List<MapPlugin> plugins) {
    for (var plugin in plugins) {
      if (plugin.supportsLayer(options)) {
        return plugin.createLayer(options, mapState, _merge(options));
      }
    }
    if (options is TileLayerOptions) {
      return TileLayer(
        options: options,
        mapState: mapState,
        stream: _merge(options),
      );
    }
    if (options is MarkerLayerOptions) {
      return MarkerLayer(options, mapState, _merge(options));
    }
    if (options is MultiMarkerLayerOptions) {
      return MultiMarkerLayer(options, mapState, _merge(options));
    }
    if (options is PolylineLayerOptions) {
      return PolylineLayer(options, mapState, _merge(options));
    }
    if (options is MultiPolylineLayerOptions) {
      return MultiPolylineLayer(options, mapState, _merge(options));
    }
    if (options is MultiPolygonLayerOptions) {
      return MultiPolygonLayer(options, mapState, _merge(options));
    }
    if (options is PolygonLayerOptions) {
      return PolygonLayer(options, mapState, _merge(options));
    }
    if (options is CircleLayerOptions) {
      return CircleLayer(options, mapState, _merge(options));
    }
    if (options is GroupLayerOptions) {
      return GroupLayer(options, mapState, _merge(options));
    }
    if (options is OverlayImageLayerOptions) {
      return OverlayImageLayer(options, mapState, _merge(options));
    }
    throw (StateError("""
Can't find correct layer for $options. Perhaps when you create your FlutterMap you need something like this:

    options: new MapOptions(plugins: [MyFlutterMapPlugin()])"""));
  }
}
