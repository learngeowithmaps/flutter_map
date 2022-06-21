import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_map/plugin_api.dart';

/// Common type between all LayerOptions.
///
/// All LayerOptions have access to a stream that notifies when the map needs
/// rebuilding.
typedef void LayerElementDragCallback<T>(
  T element,
  PointerMoveEvent dragDetails,
);

abstract class LayerOptions<LayerElementType> {
  final Key? key;
  final Stream<Null>? rebuild;

  LayerOptions({this.key, this.rebuild});
}
