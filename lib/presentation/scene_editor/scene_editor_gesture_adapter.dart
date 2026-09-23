// Flutter Gesture Adapter for SceneEditor (Phase 4B)
// Manages coordinate transformations between local screen gestures and domain TablePoints.

import 'package:flutter/material.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../rendering/scene/scene_viewport.dart';

class SceneEditorGestureAdapter {
  const SceneEditorGestureAdapter();

  /// Converts raw local screen GestureDetector [localOffset] to logical painter viewport [Offset].
  ///
  /// In vertical mode (`isVertical == true`), logical viewport coordinates equal local screen coordinates.
  /// In horizontal mode (`isVertical == false`), Painter applies:
  /// `canvas.rotate(-pi / 2)` and `canvas.translate(-size.height, 0)`
  /// Forward transform mapping raw screen `(sx, sy)` to logical `(lx, ly)`:
  /// `lx = size.height - sy`
  /// `ly = sx`
  Offset localOffsetToViewportOffset(
    Offset localOffset,
    Size size,
    bool isVertical,
  ) {
    if (isVertical) return localOffset;
    return Offset(size.height - localOffset.dy, localOffset.dx);
  }

  /// Converts logical painter viewport [viewportOffset] back to raw local screen [Offset].
  ///
  /// Inverse transform mapping logical `(lx, ly)` to raw screen `(sx, sy)`:
  /// `sx = ly`
  /// `sy = size.height - lx`
  Offset viewportOffsetToLocalOffset(
    Offset viewportOffset,
    Size size,
    bool isVertical,
  ) {
    if (isVertical) return viewportOffset;
    return Offset(viewportOffset.dy, size.height - viewportOffset.dx);
  }

  /// Maps a raw local screen [localOffset] to normalized [TablePoint] (u, v in [0, 1]^2).
  TablePoint localOffsetToTablePoint(
    Offset localOffset,
    SceneViewport viewport,
    bool isVertical,
  ) {
    final vpOffset = localOffsetToViewportOffset(
      localOffset,
      viewport.canvasSize,
      isVertical,
    );
    return viewport.offsetToTablePoint(vpOffset);
  }

  /// Maps a normalized [TablePoint] to raw local screen [Offset].
  Offset tablePointToLocalOffset(
    TablePoint point,
    SceneViewport viewport,
    bool isVertical,
  ) {
    final vpOffset = viewport.tablePointToOffset(point);
    return viewportOffsetToLocalOffset(
      vpOffset,
      viewport.canvasSize,
      isVertical,
    );
  }

  /// Checks if a raw local screen [localOffset] falls within visible interactive bounds.
  ///
  /// Standard tools require points to fall inside `viewport.playfieldRect`.
  /// Rail tools (e.g. `cushionNumber`) allow interactions within outer table rail bounds.
  bool isPointInVisibleBounds(
    Offset localOffset,
    SceneViewport viewport,
    bool isVertical, {
    bool isRailTool = false,
  }) {
    final vpOffset = localOffsetToViewportOffset(
      localOffset,
      viewport.canvasSize,
      isVertical,
    );

    if (isRailTool) {
      // Rail tools allow taps within outer canvas dimensions
      final double w = isVertical
          ? viewport.canvasSize.width
          : viewport.canvasSize.height;
      final double h = isVertical
          ? viewport.canvasSize.height
          : viewport.canvasSize.width;
      return vpOffset.dx >= 0.0 &&
          vpOffset.dx <= w &&
          vpOffset.dy >= 0.0 &&
          vpOffset.dy <= h;
    }

    return viewport.playfieldRect.contains(vpOffset);
  }
}
