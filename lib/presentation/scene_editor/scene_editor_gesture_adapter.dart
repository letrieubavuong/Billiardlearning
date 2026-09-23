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

  /// Converts raw local screen [localOffset] to logical painter viewport [Offset]
  /// and clamps it to `viewport.playfieldRect` bounds, returning a [TablePoint]
  /// constrained to the CURRENT VISIBLE CROP window.
  TablePoint localOffsetToVisibleTablePoint(
    Offset localOffset,
    SceneViewport viewport,
    bool isVertical,
  ) {
    final vpOffset = localOffsetToViewportOffset(
      localOffset,
      viewport.canvasSize,
      isVertical,
    );

    // Clamp to visible playfieldRect boundaries
    final double clampedX = vpOffset.dx.clamp(
      viewport.playfieldRect.left,
      viewport.playfieldRect.right,
    );
    final double clampedY = vpOffset.dy.clamp(
      viewport.playfieldRect.top,
      viewport.playfieldRect.bottom,
    );

    return viewport.offsetToTablePoint(Offset(clampedX, clampedY));
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

  /// Detects rail side ('top', 'bottom', 'left', 'right') and projects local rail tap
  /// to canonical table edge point. Returns null if pointer is inside playfield or outside table.
  CushionRailHit? detectRailRegion(
    Offset localOffset,
    SceneViewport viewport,
    bool isVertical,
  ) {
    final vpOffset = localOffsetToViewportOffset(
      localOffset,
      viewport.canvasSize,
      isVertical,
    );

    // Reject middle-of-table taps
    if (viewport.playfieldRect.contains(vpOffset)) {
      return null;
    }

    final double w = isVertical
        ? viewport.canvasSize.width
        : viewport.canvasSize.height;
    final double h = isVertical
        ? viewport.canvasSize.height
        : viewport.canvasSize.width;

    // Check if outside total canvas bounds
    if (vpOffset.dx < 0 ||
        vpOffset.dx > w ||
        vpOffset.dy < 0 ||
        vpOffset.dy > h) {
      return null;
    }

    final bool hasRightRail =
        viewport.viewMode != SceneViewMode.halfWidth &&
        viewport.viewMode != SceneViewMode.halfWidthHalfLength &&
        viewport.viewMode != SceneViewMode.halfWidthThirdLength &&
        viewport.viewMode != SceneViewMode.halfWidthQuarterLength;

    final isTopCandidate = vpOffset.dy < viewport.playfieldRect.top;
    final isBottomCandidate =
        viewport.hasBottomRail && vpOffset.dy > viewport.playfieldRect.bottom;
    final isLeftCandidate = vpOffset.dx < viewport.playfieldRect.left;
    final isRightCandidate =
        hasRightRail && vpOffset.dx > viewport.playfieldRect.right;

    final candidates = <String, double>{};
    if (isTopCandidate) {
      candidates['top'] = (viewport.playfieldRect.top - vpOffset.dy).abs();
    }
    if (isBottomCandidate) {
      candidates['bottom'] = (vpOffset.dy - viewport.playfieldRect.bottom)
          .abs();
    }
    if (isLeftCandidate) {
      candidates['left'] = (viewport.playfieldRect.left - vpOffset.dx).abs();
    }
    if (isRightCandidate) {
      candidates['right'] = (vpOffset.dx - viewport.playfieldRect.right).abs();
    }

    if (candidates.isEmpty) return null;

    // Select side with minimal distance to cushion line
    String bestSide = candidates.keys.first;
    double minDistance = candidates[bestSide]!;
    for (final entry in candidates.entries) {
      if (entry.value < minDistance) {
        minDistance = entry.value;
        bestSide = entry.key;
      }
    }

    TablePoint projPoint;
    switch (bestSide) {
      case 'top':
        final u =
            (vpOffset.dx - viewport.playfieldRect.left) /
            viewport.fullTablePixelWidth;
        projPoint = TablePoint(u.clamp(0.0, 1.0), 0.0);
        break;
      case 'bottom':
        final u =
            (vpOffset.dx - viewport.playfieldRect.left) /
            viewport.fullTablePixelWidth;
        projPoint = TablePoint(u.clamp(0.0, 1.0), 1.0);
        break;
      case 'left':
        final v =
            (vpOffset.dy - viewport.playfieldRect.top) /
            viewport.fullTablePixelHeight;
        projPoint = TablePoint(0.0, v.clamp(0.0, 1.0));
        break;
      case 'right':
        final v =
            (vpOffset.dy - viewport.playfieldRect.top) /
            viewport.fullTablePixelHeight;
        projPoint = TablePoint(1.0, v.clamp(0.0, 1.0));
        break;
      default:
        return null;
    }

    return CushionRailHit(side: bestSide, projectedPoint: projPoint);
  }
}

class CushionRailHit {
  final String side;
  final TablePoint projectedPoint;

  const CushionRailHit({required this.side, required this.projectedPoint});
}
