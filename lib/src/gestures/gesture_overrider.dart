/* abstract class _MapGestureOverrideController {
  bool onPointerDown();
  bool onPointerCancel();
  bool onPointerUp();
  bool onTap();
  bool onLongPress();
  bool onDoubleTap();
  bool onScaleStart();
  bool onScaleUpdate();
  bool onScaleEnd();
  bool onTapUp();
} */

import 'package:flutter/material.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';

typedef MapPointerDownEventListener = bool Function(PointerDownEvent event);
typedef MapPointerCancelEventListener = bool Function(PointerCancelEvent event);
typedef MapPointerUpEventListener = bool Function(PointerUpEvent event);
typedef MapTapPositionCallback = bool Function(TapPosition position);
typedef MapGestureScaleStartCallback = bool Function(ScaleStartDetails details);
typedef MapGestureScaleUpdateCallback = bool Function(
    ScaleUpdateDetails details);
typedef MapGestureScaleEndCallback = bool Function(ScaleEndDetails details);
typedef MapGestureTapUpCallback = bool Function(TapUpDetails details);

class MapGestureOverrider extends StatefulWidget {
  final MapPointerDownEventListener? onPointerDown;
  final MapPointerCancelEventListener? onPointerCancel;
  final MapPointerUpEventListener? onPointerUp;
  final MapTapPositionCallback? onTap;
  final MapTapPositionCallback? onLongPress;
  final MapTapPositionCallback? onDoubleTap;
  final MapGestureScaleStartCallback? onScaleStart;
  final MapGestureScaleUpdateCallback? onScaleUpdate;
  final MapGestureScaleEndCallback? onScaleEnd;
  final MapGestureTapUpCallback? onTapUp;
  final Widget? child;
  const MapGestureOverrider(
      {Key? key,
      this.onPointerDown,
      this.onPointerCancel,
      this.onPointerUp,
      this.onTap,
      this.onLongPress,
      this.onDoubleTap,
      this.onScaleStart,
      this.onScaleUpdate,
      this.onScaleEnd,
      this.onTapUp,
      this.child})
      : super(key: key);

  @override
  _MapGestureOverriderState createState() => _MapGestureOverriderState();
}

class _MapGestureOverriderState extends State<MapGestureOverrider> {
  @override
  void initState() {
    super.initState();
    MapGestureDetector._of(context)._overrides.add(this);
  }

  @override
  void dispose() {
    MapGestureDetector._of(context)._overrides.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: widget.child,
    );
  }
}

class MapGestureDetector extends StatefulWidget {
  final MapPointerDownEventListener? onPointerDown;
  final MapPointerCancelEventListener? onPointerCancel;
  final MapPointerUpEventListener? onPointerUp;
  final MapTapPositionCallback? onTap;
  final MapTapPositionCallback? onLongPress;
  final MapTapPositionCallback? onDoubleTap;
  final MapGestureScaleStartCallback? onScaleStart;
  final MapGestureScaleUpdateCallback? onScaleUpdate;
  final MapGestureScaleEndCallback? onScaleEnd;
  final MapGestureTapUpCallback? onTapUp;
  final Widget? child;
  const MapGestureDetector({
    Key? key,
    this.child,
    this.onPointerDown,
    this.onPointerCancel,
    this.onPointerUp,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onTapUp,
  }) : super(key: key);

  static _MapGestureDetectorState _of(BuildContext context) {
    final state = context.findAncestorStateOfType<_MapGestureDetectorState>();
    if (state == null) {
      throw FlutterError(
        '_MapGestureOverrider not found for the context',
      );
    }
    return state;
  }

  @override
  _MapGestureDetectorState createState() => _MapGestureDetectorState();
}

class _MapGestureDetectorState extends State<MapGestureDetector> {
  final _positionedTapController = PositionedTapController();
  final _overrides = <_MapGestureOverriderState>[];

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        for (var override in _overrides) {
          if (!(override.widget.onPointerDown?.call(_) ?? false)) {
            widget.onPointerDown?.call(_);
          }
        }
      },
      onPointerCancel: (_) {
        for (var override in _overrides) {
          if (!(override.widget.onPointerCancel?.call(_) ?? false)) {
            widget.onPointerCancel?.call(_);
          }
        }
      },
      onPointerUp: (_) {
        for (var override in _overrides) {
          if (!(override.widget.onPointerUp?.call(_) ?? false)) {
            widget.onPointerUp?.call(_);
          }
        }
      },
      child: PositionedTapDetector2(
        controller: _positionedTapController,
        onTap: (_) {
          for (var override in _overrides) {
            if (!(override.widget.onTap?.call(_) ?? false)) {
              widget.onTap?.call(_);
            }
          }
        },
        onLongPress: (_) {
          for (var override in _overrides) {
            if (!(override.widget.onLongPress?.call(_) ?? false)) {
              widget.onLongPress?.call(_);
            }
          }
        },
        onDoubleTap: (_) {
          for (var override in _overrides) {
            if (!(override.widget.onDoubleTap?.call(_) ?? false)) {
              widget.onDoubleTap?.call(_);
            }
          }
        },
        child: GestureDetector(
          onScaleStart: (_) {
            for (var override in _overrides) {
              if (!(override.widget.onScaleStart?.call(_) ?? false)) {
                widget.onScaleStart?.call(_);
              }
            }
          },
          onScaleUpdate: (_) {
            for (var override in _overrides) {
              if (!(override.widget.onScaleUpdate?.call(_) ?? false)) {
                widget.onScaleUpdate?.call(_);
              }
            }
          },
          onScaleEnd: (_) {
            for (var override in _overrides) {
              if (!(override.widget.onScaleEnd?.call(_) ?? false)) {
                widget.onScaleEnd?.call(_);
              }
            }
          },
          onTap: _positionedTapController.onTap,
          onLongPress: _positionedTapController.onLongPress,
          onTapDown: _positionedTapController.onTapDown,
          onTapUp: (_) {
            for (var override in _overrides) {
              if (!(override.widget.onTapUp?.call(_) ?? false)) {
                widget.onTapUp?.call(_);
              }
            }
          },
          child: widget.child,
        ),
      ),
    );
  }
}
