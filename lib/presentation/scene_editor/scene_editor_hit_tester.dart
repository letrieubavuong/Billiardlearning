// Screen-space Hit Tester for SceneEditor (Phase 4B)
// Determines active selection targets in local pixel space with deterministic priority.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../application/scene_editor/scene_editor_selection.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../rendering/scene/scene_viewport.dart';
import 'scene_editor_gesture_adapter.dart';

class SceneEditorHitTester {
  final double ballHitSlopPx;
  final double pointHitSlopPx;
  final double annotationHitSlopPx;
  final double lineHitSlopPx;

  final SceneEditorGestureAdapter _adapter;

  const SceneEditorHitTester({
    this.ballHitSlopPx = 22.0,
    this.pointHitSlopPx = 20.0,
    this.annotationHitSlopPx = 24.0,
    this.lineHitSlopPx = 16.0,
    SceneEditorGestureAdapter adapter = const SceneEditorGestureAdapter(),
  }) : _adapter = adapter;

  /// Performs screen-space hit testing against [scene] entities at [localOffset].
  ///
  /// Priority:
  /// 1. Trajectory Point (`trajectoryPoint`)
  /// 2. Ball (`ball`)
  /// 3. Annotation (`annotation`)
  /// 4. Trajectory Line (`trajectory`)
  /// 5. None (`none`)
  SceneEditorSelection hitTest(
    Offset localOffset,
    BilliardScene scene,
    SceneViewport viewport,
    bool isVertical,
  ) {
    // Normal entities MUST be inside visible playfieldRect (Item 18: Normal hit region != Rail region)
    if (!_adapter.isPointInVisibleBounds(
      localOffset,
      viewport,
      isVertical,
      isRailTool: false,
    )) {
      return const SceneEditorSelection.none();
    }

    final vpOffset = _adapter.localOffsetToViewportOffset(
      localOffset,
      viewport.canvasSize,
      isVertical,
    );

    // 1. Trajectory Control Points (highest priority)
    for (final traj in scene.trajectories) {
      for (var i = 0; i < traj.points.length; i++) {
        final ptVp = viewport.tablePointToOffset(traj.points[i]);
        // Entity must be visible on screen
        if (!viewport.playfieldRect.contains(ptVp)) continue;

        final ptScreen = _adapter.tablePointToLocalOffset(
          traj.points[i],
          viewport,
          isVertical,
        );
        if ((ptScreen - localOffset).distance <= pointHitSlopPx) {
          return SceneEditorSelection.trajectoryPoint(traj.id, i);
        }
      }
    }

    // 2. Balls
    final double dynamicBallRadius = viewport.diamondSpacing * 0.1;
    final double effectiveBallSlop = math.max(
      ballHitSlopPx,
      dynamicBallRadius * 1.2,
    );

    for (final ball in scene.balls) {
      final ballVp = viewport.tablePointToOffset(ball.position);
      // Entity must be visible on screen
      if (!viewport.playfieldRect.contains(ballVp)) continue;

      final ballScreen = _adapter.tablePointToLocalOffset(
        ball.position,
        viewport,
        isVertical,
      );
      if ((ballScreen - localOffset).distance <= effectiveBallSlop) {
        return SceneEditorSelection.ball(ball.id);
      }
    }

    // 3. Annotations
    for (final ann in scene.annotations) {
      final annVp = viewport.tablePointToOffset(ann.position);
      // Entity must be visible on screen
      if (!viewport.playfieldRect.contains(annVp)) continue;

      final annScreen = _adapter.tablePointToLocalOffset(
        ann.position,
        viewport,
        isVertical,
      );
      if ((annScreen - localOffset).distance <= annotationHitSlopPx) {
        return SceneEditorSelection.annotation(ann.id);
      }
    }

    // 4. Trajectory Line Segments
    for (final traj in scene.trajectories) {
      if (traj.points.length < 2) continue;
      for (var i = 0; i < traj.points.length - 1; i++) {
        final p1Vp = viewport.tablePointToOffset(traj.points[i]);
        final p2Vp = viewport.tablePointToOffset(traj.points[i + 1]);

        // Clip line segment to visible playfieldRect (Item 17)
        final clipped = _clipSegmentToRect(p1Vp, p2Vp, viewport.playfieldRect);
        if (clipped == null) continue; // Fully outside visible crop

        if (_distanceToSegment(vpOffset, clipped.a, clipped.b) <=
            lineHitSlopPx) {
          return SceneEditorSelection.trajectory(traj.id);
        }
      }
    }

    // 5. None
    return const SceneEditorSelection.none();
  }

  /// Clips segment [p0]-[p1] to [rect] using Liang-Barsky line clipping.
  _ClippedSegment? _clipSegmentToRect(Offset p0, Offset p1, Rect rect) {
    double t0 = 0.0;
    double t1 = 1.0;
    final dx = p1.dx - p0.dx;
    final dy = p1.dy - p0.dy;

    final p = [-dx, dx, -dy, dy];
    final q = [
      p0.dx - rect.left,
      rect.right - p0.dx,
      p0.dy - rect.top,
      rect.bottom - p0.dy,
    ];

    for (int i = 0; i < 4; i++) {
      if (p[i] == 0) {
        if (q[i] < 0) return null; // Parallel and outside
      } else {
        final r = q[i] / p[i];
        if (p[i] < 0) {
          if (r > t1) return null;
          if (r > t0) t0 = r;
        } else {
          if (r < t0) return null;
          if (r < t1) t1 = r;
        }
      }
    }

    if (t0 > t1) return null;
    return _ClippedSegment(
      Offset(p0.dx + t0 * dx, p0.dy + t0 * dy),
      Offset(p0.dx + t1 * dx, p0.dy + t1 * dy),
    );
  }

  /// Calculates perpendicular distance from point [p] to line segment [a]-[b] in pixel space.
  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final l2 = (b - a).distanceSquared;
    if (l2 == 0) return (p - a).distance;

    final double t = math.max(
      0.0,
      math.min(
        1.0,
        ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2,
      ),
    );
    final projection = Offset(
      a.dx + t * (b.dx - a.dx),
      a.dy + t * (b.dy - a.dy),
    );
    return (p - projection).distance;
  }
}

class _ClippedSegment {
  final Offset a;
  final Offset b;

  const _ClippedSegment(this.a, this.b);
}
