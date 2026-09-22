// Modular ScenePainter facade for Billiardlearning Phase 3

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/value_objects/value_objects.dart';
import 'scene_viewport.dart';
import 'scene_render_model.dart';
import 'table_renderer.dart';
import 'ball_renderer.dart';
import 'trajectory_renderer.dart';
import 'annotation_renderer.dart';

/// Facade [CustomPainter] coordinating table, ball, trajectory, and annotation renderers.
class ScenePainter extends CustomPainter {
  final SceneRenderModel model;
  final TableRenderer tableRenderer;
  final BallRenderer ballRenderer;
  final TrajectoryRenderer trajectoryRenderer;
  final AnnotationRenderer annotationRenderer;

  ScenePainter({
    required this.model,
    this.tableRenderer = const TableRenderer(),
    this.ballRenderer = const BallRenderer(),
    this.trajectoryRenderer = const TrajectoryRenderer(),
    this.annotationRenderer = const AnnotationRenderer(),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final viewport = SceneViewport(
      canvasSize: size,
      viewMode: model.viewMode,
      isVertical: model.isVertical,
      hasBottomRail: model.hasBottomRail,
    );

    final double w = model.isVertical ? size.width : size.height;
    final bool hasRightRail =
        model.viewMode != SceneViewMode.halfWidth &&
        model.viewMode != SceneViewMode.halfWidthHalfLength &&
        model.viewMode != SceneViewMode.halfWidthThirdLength &&
        model.viewMode != SceneViewMode.halfWidthQuarterLength;

    final double scale = w / (hasRightRail ? 124.0 : 62.0);
    final double textScale = 1.0 + (scale - 1.0) * 0.15;
    final double lineScale = 1.0 + (scale - 1.0) * 0.15;

    if (!model.isVertical) {
      canvas.save();
      canvas.rotate(-math.pi / 2);
      canvas.translate(-size.height, 0);
    }

    // 1. Table Cloth & Cushions
    tableRenderer.drawClothAndCushions(canvas, viewport, model.theme);

    // 2. Table Grid, Ticks, Diamonds
    tableRenderer.drawGridAndDiamonds(canvas, viewport, model.theme, lineScale);

    // 3. DiagramSystem Overlays
    tableRenderer.drawSystemOverlay(
      canvas,
      viewport,
      model.diagramSystemIndex,
      textScale,
    );

    // 4. Angle Arcs
    annotationRenderer.drawAngles(
      canvas,
      viewport,
      model.angles,
      model.theme,
      lineScale,
      textScale,
    );

    // 5. Trajectories
    final timings = trajectoryRenderer.computeTimings(model.trajectories);
    trajectoryRenderer.drawTrajectories(
      canvas,
      viewport,
      model.trajectories,
      timings,
      model.animationProgress,
      model.theme,
      lineScale,
    );

    // 6. Balls
    final double ballRadius = viewport.diamondSpacing * 0.1;
    double motionProgress = 0.0;
    if (model.animationProgress > 0) {
      if (model.animationProgress <= 0.2) {
        motionProgress = 0.0;
      } else {
        motionProgress = (model.animationProgress - 0.2) / 0.8;
      }
    }

    for (final ball in model.balls) {
      TablePoint relativePos = ball.position;
      double rollAngle = 0.0;

      if (model.animationProgress > 0 && !ball.isGhost && !ball.isOutline) {
        for (int i = 0; i < model.trajectories.length; i++) {
          final path = model.trajectories[i];
          if (path.points.isNotEmpty) {
            final double du = ball.position.u - path.points.first.u;
            final double dv = ball.position.v - path.points.first.v;
            final double dist = math.sqrt(du * du + dv * dv);
            if (dist < 0.05) {
              // Draw ghost shadow at initial position
              ballRenderer.drawGhostShadow(
                canvas,
                viewport,
                ball,
                ballRadius,
                lineScale,
              );

              final timing = i < timings.length
                  ? timings[i]
                  : const PathTiming(0, 1);
              final double totalLength = trajectoryRenderer.getPathLength(
                path.points,
              );

              if (motionProgress < timing.startTime) {
                relativePos = path.points.first;
                rollAngle = 0.0;
              } else if (motionProgress > timing.endTime) {
                relativePos = path.points.last;
                rollAngle = totalLength * 50.0;
              } else {
                final double localT =
                    (motionProgress - timing.startTime) /
                    (timing.endTime - timing.startTime);
                relativePos = trajectoryRenderer.getPositionOnPath(
                  path.points,
                  localT,
                );
                final double easedT = localT * (2.0 - localT);
                rollAngle = totalLength * easedT * 50.0;
              }
              break;
            }
          }
        }
      }

      final animatedBall = BallRenderItem(
        position: relativePos,
        color: ball.color,
        opacity: ball.opacity,
        isGhost: ball.isGhost,
        isOutline: ball.isOutline,
        ballTypeIndex: ball.ballTypeIndex,
        rotationInRadians: ball.rotationInRadians,
        text: ball.text,
      );

      ballRenderer.drawBall(
        canvas,
        viewport,
        animatedBall,
        ballRadius,
        lineScale,
        additionalRotation: rollAngle,
      );
    }

    // 7. Text Annotations
    annotationRenderer.drawAnnotations(
      canvas,
      viewport,
      model.annotations,
      model.theme,
      textScale,
    );

    // 8. Effet Mini Diagram Overlay
    if (model.effetData != null) {
      annotationRenderer.drawMiniEffet(
        canvas,
        viewport,
        model.effetData!,
        lineScale,
        textScale,
      );
    }

    if (!model.isVertical) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ScenePainter oldDelegate) {
    return model != oldDelegate.model;
  }
}
