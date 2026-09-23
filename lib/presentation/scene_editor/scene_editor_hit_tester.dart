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
    // Check if pointer is within visible bounds or rail region
    if (!_adapter.isPointInVisibleBounds(
      localOffset,
      viewport,
      isVertical,
      isRailTool: true,
    )) {
      return const SceneEditorSelection.none();
    }

    // 1. Trajectory Control Points (highest priority)
    for (final traj in scene.trajectories) {
      for (var i = 0; i < traj.points.length; i++) {
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
        final p1 = _adapter.tablePointToLocalOffset(
          traj.points[i],
          viewport,
          isVertical,
        );
        final p2 = _adapter.tablePointToLocalOffset(
          traj.points[i + 1],
          viewport,
          isVertical,
        );
        if (_distanceToSegment(localOffset, p1, p2) <= lineHitSlopPx) {
          return SceneEditorSelection.trajectory(traj.id);
        }
      }
    }

    // 5. None
    return const SceneEditorSelection.none();
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
