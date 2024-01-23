import 'package:flutter/material.dart';

typedef LayerGestureDragStartCallback = bool Function(
    ScaleStartDetails details);
typedef LayerGestureDragUpdateCallback = bool Function(
    ScaleUpdateDetails details);
typedef LayerGestureDragEndCallback = bool Function(ScaleEndDetails details);
typedef LayerGestureTapDownCallback = bool Function(TapDownDetails details);
typedef LayerGestureTapUpCallback = bool Function(TapUpDetails details);
typedef LayerGestureLongPressStartCallback = bool Function(
    LongPressStartDetails details);

abstract class MasterGestureSubscriptionController {
  List<LayerGestureDragStartCallback> dragStartCallbacks = [];
  List<LayerGestureDragUpdateCallback> dragUpdateCallbacks = [];
  List<LayerGestureDragEndCallback> dragEndCallbacks = [];
  List<LayerGestureTapDownCallback> tapDownCallbacks = [];
  List<LayerGestureTapUpCallback> tapUpCallbacks = [];
  List<LayerGestureTapUpCallback> tapCallbacks = [];
  List<VoidCallback> tapCancelCallbacks = [];

  LayerGestureDragStartCallback listenForDragStart(
      LayerGestureDragStartCallback callback) {
    dragStartCallbacks.add(callback);
    return callback;
  }

  LayerGestureDragUpdateCallback listenForDragUpdate(
      LayerGestureDragUpdateCallback callback) {
    dragUpdateCallbacks.add(callback);
    return callback;
  }

  LayerGestureDragEndCallback listenForDragEnd(
      LayerGestureDragEndCallback callback) {
    dragEndCallbacks.add(callback);
    return callback;
  }

  LayerGestureTapDownCallback listenForTapDown(
      LayerGestureTapDownCallback callback) {
    tapDownCallbacks.add(callback);
    return callback;
  }

  LayerGestureTapUpCallback listenForTapUp(LayerGestureTapUpCallback callback) {
    tapUpCallbacks.add(callback);
    return callback;
  }

  LayerGestureTapUpCallback listenForTap(LayerGestureTapUpCallback callback) {
    tapCallbacks.add(callback);
    return callback;
  }

  bool removeListener(Function callback) {
    return dragStartCallbacks.remove(callback) ||
        dragEndCallbacks.remove(callback) ||
        dragUpdateCallbacks.remove(callback) ||
        tapDownCallbacks.remove(callback) ||
        tapUpCallbacks.remove(callback) ||
        tapCallbacks.remove(callback);
  }

  VoidCallback listenForTapCancel(VoidCallback callback) {
    tapCancelCallbacks.add(callback);
    return callback;
  }
}

class FlutterMapLayerGestureListener extends StatefulWidget {
  final LayerGestureTapDownCallback? onTapDown;
  final LayerGestureTapUpCallback? onTapUp;
  final LayerGestureTapUpCallback? onTap;
  final LayerGestureDragStartCallback? onDragStart;
  final LayerGestureDragUpdateCallback? onDragUpdate;
  final LayerGestureDragEndCallback? onDragEnd;
  final LayerGestureTapUpCallback? onLongPress;
  final LayerGestureTapDownCallback? onDoubleTap;
  final VoidCallback? onTapCancel;
  final Widget child;

  const FlutterMapLayerGestureListener({
    Key? key,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    required this.child,
    this.onLongPress,
    this.onDoubleTap,
    this.onTapCancel,
  }) : super(key: key);

  @override
  State<FlutterMapLayerGestureListener> createState() =>
      _FlutterMapLayerGestureListenerState();
}

class _FlutterMapLayerGestureListenerState
    extends State<FlutterMapLayerGestureListener> {
  final _allListeners = <Function>[];
  @override
  void initState() {
    if (widget.onDragStart != null) {
      _allListeners.add(FlutterMapMasterGestureDetector.of(context)
          .listenForDragStart(widget.onDragStart!));
    }
    if (widget.onDragUpdate != null) {
      _allListeners.add(FlutterMapMasterGestureDetector.of(context)
          .listenForDragUpdate(widget.onDragUpdate!));
    }
    if (widget.onDragEnd != null) {
      _allListeners.add(FlutterMapMasterGestureDetector.of(context)
          .listenForDragEnd(widget.onDragEnd!));
    }
    if (widget.onTapDown != null) {
      _allListeners.add(FlutterMapMasterGestureDetector.of(context)
          .listenForTapDown(widget.onTapDown!));
    }
    if (widget.onTapUp != null) {
      _allListeners.add(FlutterMapMasterGestureDetector.of(context)
          .listenForTapUp(widget.onTapUp!));
    }
    if (widget.onTap != null) {
      _allListeners.add(FlutterMapMasterGestureDetector.of(context)
          .listenForTap(widget.onTap!));
    }
    if (widget.onTapCancel != null) {
      _allListeners.add(FlutterMapMasterGestureDetector.of(context)
          .listenForTapCancel(widget.onTapCancel!));
    }
    super.initState();
  }
  //
  // @override
  // void dispose() {
  //   for (var listener in _allListeners) {
  //     FlutterMapMasterGestureDetector.of(context).removeListener(listener);
  //   }
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class FlutterMapMasterGestureDetector extends StatefulWidget {
  final Widget child;
  final LayerGestureTapDownCallback? onTapDown;
  final LayerGestureTapUpCallback? onTapUp;
  final LayerGestureTapUpCallback? onTap;
  final LayerGestureDragStartCallback? onDragStart;
  final LayerGestureDragUpdateCallback? onDragUpdate;
  final LayerGestureDragEndCallback? onDragEnd;
  final LayerGestureLongPressStartCallback? onLongPress;
  final LayerGestureTapDownCallback? onDoubleTap;
  final VoidCallback? onTapCancel;
  const FlutterMapMasterGestureDetector({
    Key? key,
    required this.child,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onDoubleTap,
    this.onTapCancel,
  }) : super(key: key);

  static MasterGestureSubscriptionController of(BuildContext context) {
    final state = context
        .findAncestorStateOfType<_FlutterMapMasterGestureDetectorState>();
    if (state == null) {
      throw FlutterError("add LayerGestureHandler above map layers");
    }
    return state.getController;
  }

  @override
  State<FlutterMapMasterGestureDetector> createState() =>
      _FlutterMapMasterGestureDetectorState();
}

class _FlutterMapMasterGestureDetectorState
    extends State<FlutterMapMasterGestureDetector>
    with MasterGestureSubscriptionController {
  MasterGestureSubscriptionController get getController => this;

  @override
  void initState() {
    super.initState();
  }

  bool _handle<CallbackType extends Function, DetailsType>(
      List<CallbackType> callabacks, DetailsType deets) {
    for (var callback in callabacks.reversed) {
      if (callback(deets)) {
        return true;
      }
    }
    return false;
  }

  TapDownDetails? _lastTapDown, _lastDoubleTapDown;
  TapUpDetails? _lastTapUp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (deets) {
        if (!_handle(dragStartCallbacks, deets)) {
          widget.onDragStart?.call(deets);
        }
      },
      onScaleUpdate: (deets) {
        if (!_handle(dragUpdateCallbacks, deets)) {
          widget.onDragUpdate?.call(deets);
        }
      },
      onScaleEnd: (deets) {
        if (!_handle(dragEndCallbacks, deets)) {
          widget.onDragEnd?.call(deets);
        }
      },
      onDoubleTap: () {
        widget.onDoubleTap?.call(_lastDoubleTapDown!);
      },
      onDoubleTapDown: (deets) {
        _lastDoubleTapDown = deets;
      },
      onDoubleTapCancel: () {
        _lastDoubleTapDown = null;
      },
      onLongPressStart: widget.onLongPress,
      onTapCancel: () {
        for (var element in tapCancelCallbacks) {
          element();
        }
      },
      onTapDown: (deets) {
        _lastTapDown = deets;
        if (!_handle(tapDownCallbacks, deets)) {
          widget.onTapDown?.call(deets);
        }
      },
      onTapUp: (deets) {
        _lastTapUp = deets;
        if (!_handle(tapUpCallbacks, deets)) {
          widget.onTapUp?.call(deets);
        }
        if (_lastTapDown?.localPosition == _lastTapUp!.localPosition) {
          if (!_handle(tapCallbacks, deets)) {
            widget.onTap?.call(deets);
          }
        }
      },
      child: widget.child,
    );
  }
}
