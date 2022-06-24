import 'package:flutter/material.dart';

typedef LayerGestureDragStartCallback = bool Function(
    ScaleStartDetails details);
typedef LayerGestureDragUpdateCallback = bool Function(
    ScaleUpdateDetails details);
typedef LayerGestureDragEndCallback = bool Function(ScaleEndDetails details);
typedef LayerGestureTapDownCallback = bool Function(TapDownDetails details);
typedef LayerGestureTapUpCallback = bool Function(TapUpDetails details);
typedef LayerGestureLongPressCallback = bool Function(
    LongPressStartDetails details);

abstract class MasterGestureSubscriptionController {
  List<LayerGestureDragStartCallback> dragStartCallbacks = [];
  List<LayerGestureDragUpdateCallback> dragUpdateCallbacks = [];
  List<LayerGestureDragEndCallback> dragEndCallbacks = [];
  List<LayerGestureTapDownCallback> tapDownCallbacks = [];
  List<LayerGestureTapUpCallback> tapUpCallbacks = [];
  List<LayerGestureTapUpCallback> tapCallbacks = [];
  List<VoidCallback> tapCancelCallbacks = [];
  List<LayerGestureLongPressCallback> longPressCallbacks = [];

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

  Function listenForLongPress(LayerGestureLongPressCallback callback) {
    longPressCallbacks.add(callback);
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
  final LayerGestureLongPressCallback? onLongPress;
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
    if (widget.onLongPress != null) {
      _allListeners.add(FlutterMapMasterGestureDetector.of(context)
          .listenForLongPress(widget.onLongPress!));
    }
    super.initState();
  }

  @override
  void dispose() {
    for (var listener in _allListeners) {
      FlutterMapMasterGestureDetector.of(context).removeListener(listener);
    }
    super.dispose();
  }

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
  final LayerGestureLongPressCallback? onLongPress;
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

  late final Widget _gestureDetector;
  Offset? _lastPosition;

  @override
  void initState() {
    _gestureDetector = GestureDetector(
      onScaleStart: (deets) {
        if (widget.onDragStart?.call(deets) ?? false) {
          return;
        }
        _handle(dragStartCallbacks, deets);
      },
      onScaleUpdate: (deets) {
        if (widget.onDragUpdate?.call(deets) ?? false) {
          return;
        }
        _handle(dragUpdateCallbacks, deets);
      },
      onScaleEnd: (deets) {
        if (widget.onDragEnd?.call(deets) ?? false) {
          return;
        }
        _handle(dragEndCallbacks, deets);
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
      onLongPressStart: (deets) {
        if (widget.onLongPress?.call(deets) ?? false) {
          return;
        }
        _handle(longPressCallbacks, deets);
      },
      onTapCancel: () {
        for (var element in tapCancelCallbacks) {
          element();
        }
      },
      onTapDown: (deets) {
        _lastTapDown = deets;
        if (widget.onTapDown?.call(deets) ?? false) {
          return;
        }
        _handle(tapDownCallbacks, deets);
      },
      onTapUp: (deets) {
        _lastTapUp = deets;
        if (widget.onTapUp?.call(deets) ?? false) {
          return;
        }
        _handle(tapUpCallbacks, deets);
        if (_lastTapDown?.localPosition == _lastTapUp!.localPosition) {
          if (widget.onTap?.call(deets) ?? false) {
            return;
          }
          _handle(tapCallbacks, deets);
        }
      },
      child: widget.child,
    );
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

  final painter = PointerPainter();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _gestureDetector,
        CustomPaint(
          key: ValueKey(
            DateTime.now(),
          ),
          foregroundPainter: painter,
        )
      ],
    );
  }

  void paint(Offset paintLocation) async {
    setState(() {
      painter.pointLocation = Offset(paintLocation.dx, paintLocation.dy);
    });
    await Future.delayed(
      const Duration(
        milliseconds: 600,
      ),
    );
    if (mounted) {
      setState(() {
        painter.pointLocation = null;
      });
    }
  }
}

class PointerPainter extends CustomPainter {
  Offset? pointLocation;
  final radius = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    if (pointLocation == null) {
      paint.color = Colors.transparent;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    } else {
      paint.color = Colors.black;
      canvas.drawCircle(
        pointLocation!,
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    throw true;
  }
}

/* class GestureFeedback extends StatefulWidget {
  final Offset? position;
  const GestureFeedback({
    Key? key,
    required this.position,
  }) : super(key: key);

  @override
  State<GestureFeedback> createState() => _GestureFeedbackState();
}

class _GestureFeedbackState extends State<GestureFeedback> {
  Offset? _position;
  @override
  void initState() {
    _position = widget.position;
    super.initState();
    if (widget.position != null) {
      Future.delayed(
        const Duration(milliseconds: 800),
        () {
          setState(() {
            _position = null;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_position == null) {
      return SizedBox();
    }
    return Positioned(
      left: widget.position!.dx,
      top: widget.position!.dx,
      width: 12,
      height: 12,
      child: Container(
        color: Colors.green,
      ),
    );
  }
}
 */