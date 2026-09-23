// Selection Overlay Painter for SceneEditor (Phase 4B)
// Renders visual selection rings, handles, and indicators without altering canonical scene state.

import 'package:flutter/material.dart';
import '../../application/scene_editor/scene_editor_selection.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../rendering/scene/scene_viewport.dart';
import 'scene_editor_gesture_adapter.dart';

class SceneEditorOverlay extends CustomPainter {
  final BilliardScene scene;
  final SceneEditorSelection selection;
  final SceneViewport viewport;
  final bool isVertical;
  final SceneEditorGestureAdapter adapter;

  SceneEditorOverlay({
    required this.scene,
    required this.selection,
    required this.viewport,
    required this.isVertical,
    this.adapter = const SceneEditorGestureAdapter(),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selection.type == SceneEditorSelectionType.none) return;

    final ringPaint = Paint()
      ..color =
          const Color(0xFFFFD700) // Gold selection ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final handleFillPaint = Paint()
      ..color =
          const Color(0xFF00FFFF) // Cyan point handle fill
      ..style = PaintingStyle.fill;

    final handleStrokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    switch (selection.type) {
      case SceneEditorSelectionType.ball:
        final ball = scene.balls.firstWhere(
          (b) => b.id == selection.targetId,
          orElse: () => BallPosition(
            id: '',
            ballType: '',
            position: TablePoint(0.0, 0.0),
          ),
        );
        if (ball.id.isEmpty) return;

        final centerScreen = adapter.tablePointToLocalOffset(
          ball.position,
          viewport,
          isVertical,
        );
        final double radius = (viewport.diamondSpacing * 0.1) + 4.0;
        canvas.drawCircle(centerScreen, radius, ringPaint);
        break;

      case SceneEditorSelectionType.annotation:
        final ann = scene.annotations.firstWhere(
          (a) => a.id == selection.targetId,
          orElse: () =>
              SceneAnnotation(id: '', text: '', position: TablePoint(0.0, 0.0)),
        );
        if (ann.id.isEmpty) return;

        final centerScreen = adapter.tablePointToLocalOffset(
          ann.position,
          viewport,
          isVertical,
        );
        final rect = Rect.fromCenter(
          center: centerScreen,
          width: 48.0,
          height: 28.0,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6.0)),
          ringPaint,
        );
        break;

      case SceneEditorSelectionType.trajectoryPoint:
        final traj = scene.trajectories.firstWhere(
          (t) => t.id == selection.targetId,
          orElse: () => const TrajectoryLine(id: ''),
        );
        final ptIdx = selection.pointIndex;
        if (traj.id.isEmpty ||
            ptIdx == null ||
            ptIdx < 0 ||
            ptIdx >= traj.points.length) {
          return;
        }

        final ptScreen = adapter.tablePointToLocalOffset(
          traj.points[ptIdx],
          viewport,
          isVertical,
        );
        canvas.drawCircle(ptScreen, 8.0, handleFillPaint);
        canvas.drawCircle(ptScreen, 8.0, handleStrokePaint);
        break;

      case SceneEditorSelectionType.trajectory:
        final traj = scene.trajectories.firstWhere(
          (t) => t.id == selection.targetId,
          orElse: () => const TrajectoryLine(id: ''),
        );
        if (traj.id.isEmpty) return;

        for (final pt in traj.points) {
          final ptScreen = adapter.tablePointToLocalOffset(
            pt,
            viewport,
            isVertical,
          );
          canvas.drawCircle(ptScreen, 5.0, ringPaint);
        }
        break;

      case SceneEditorSelectionType.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant SceneEditorOverlay oldDelegate) {
    return scene != oldDelegate.scene ||
        selection != oldDelegate.selection ||
        viewport.canvasSize != oldDelegate.viewport.canvasSize ||
        isVertical != oldDelegate.isVertical;
  }
}
