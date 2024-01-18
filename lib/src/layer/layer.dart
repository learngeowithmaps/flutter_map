import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Common type between all LayerOptions.
///
/// All LayerOptions have access to a stream that notifies when the map needs
/// rebuilding.
typedef LayerElementDragCallback<T> = void Function(
  T element,
  PointerMoveEvent dragDetails,
);

abstract class LayerOptions<LayerElementType> {
  final Key? key;
  late final StreamGroup<Null> _rebuild;

  final _interenalRebuild = StreamController<Null>();

  LayerOptions({this.key, Stream<Null>? rebuild}) {
    _rebuild = StreamGroup<Null>();
    if (rebuild != null) {
      _rebuild.add(rebuild);
    }
    _rebuild.add(_interenalRebuild.stream);
  }

  Stream<Null> get rebuild => _rebuild.stream;

  void doLayerRebuild() {
    _interenalRebuild.add(null);
  }

  void addElements(List<LayerElementType> elements) {}
}
