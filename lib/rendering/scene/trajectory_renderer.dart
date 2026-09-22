// Trajectory rendering component for Billiardlearning Phase 3

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/value_objects/value_objects.dart';
import 'scene_viewport.dart';
import 'scene_render_model.dart';
import 'legacy/legacy_playback_compatibility.dart';

export 'legacy/legacy_playback_compatibility.dart' show PathTiming;

/// Component responsible for drawing trajectory paths (solid or dashed),
/// computing visual timing fractions for progressive path playback, and
/// interpolating ball motion along path points.
class TrajectoryRenderer {
  const TrajectoryRenderer();

  /// Delegates path length to [LegacyPlaybackCompatibility].
  double getPathLength(List<TablePoint> pts) {
    return LegacyPlaybackCompatibility.getPathLength(pts);
  }

  /// Delegates position interpolation to [LegacyPlaybackCompatibility].
  TablePoint getPositionOnPath(List<TablePoint> points, double t) {
    return LegacyPlaybackCompatibility.getPositionOnPath(points, t);
  }

  /// Delegates progressive points interpolation to [LegacyPlaybackCompatibility].
  List<TablePoint> getProgressivePoints(List<TablePoint> points, double t) {
    return LegacyPlaybackCompatibility.getProgressivePoints(points, t);
  }

  /// Delegates visual path timing heuristic calculation to [LegacyPlaybackCompatibility].
  List<PathTiming> computeTimings(List<TrajectoryRenderItem> paths) {
    return LegacyPlaybackCompatibility.computeTimings(paths);
  }

  /// Draws all trajectories onto canvas.
  void drawTrajectories(
    Canvas canvas,
    SceneViewport viewport,
    List<TrajectoryRenderItem> paths,
    List<PathTiming> timings,
    double animationProgress,
    SceneRenderTheme theme,
    double lineScale,
  ) {
    double motionProgress = 0.0;
    double blinkOpacity = 1.0;
    final bool isBlinkingPhase =
        animationProgress > 0 && animationProgress <= 0.2;

    if (animationProgress > 0) {
      if (animationProgress <= 0.2) {
        motionProgress = 0.0;
        final double sinVal = math.sin(animationProgress * 5.0 * math.pi * 3.0);
        blinkOpacity = 0.2 + 0.8 * (sinVal.abs());
      } else {
        motionProgress = (animationProgress - 0.2) / 0.8;
        blinkOpacity = 1.0;
      }
    }

    for (int i = 0; i < paths.length; i++) {
      final path = paths[i];
      final timing = i < timings.length ? timings[i] : const PathTiming(0, 1);

      double localT = 0.0;
      if (isBlinkingPhase) {
        localT = 1.0;
      } else if (motionProgress >= timing.endTime) {
        localT = 1.0;
      } else if (motionProgress <= timing.startTime) {
        localT = 0.0;
      } else {
        localT =
            (motionProgress - timing.startTime) /
            (timing.endTime - timing.startTime);
      }

      final List<TablePoint> activePoints = getProgressivePoints(
        path.points,
        localT,
      );
      if (activePoints.isEmpty) continue;

      final Color pathColor =
          (path.role != null && theme.indicatorColors.containsKey(path.role))
          ? theme.indicatorColors[path.role]!
          : path.color;

      final Paint pathPaint = Paint()
        ..color = pathColor.withOpacity(
          path.opacity * (isBlinkingPhase ? blinkOpacity : 1.0),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * lineScale
        ..strokeCap = StrokeCap.round;

      for (int j = 0; j < activePoints.length - 1; j++) {
        final Offset p1 = viewport.tablePointToOffset(activePoints[j]);
        final Offset p2 = viewport.tablePointToOffset(activePoints[j + 1]);

        if (path.isDashed) {
          final double dashWidth = 4.0 * lineScale;
          final double dashSpace = 3.0 * lineScale;
          final double distance = (p2 - p1).distance;
          final int count = (distance / (dashWidth + dashSpace)).floor();
          for (int k = 0; k < count; k++) {
            final double startT = (k * (dashWidth + dashSpace)) / distance;
            final double endT =
                (k * (dashWidth + dashSpace) + dashWidth) / distance;
            canvas.drawLine(
              Offset.lerp(p1, p2, startT)!,
              Offset.lerp(p1, p2, endT)!,
              pathPaint,
            );
          }
        } else {
          canvas.drawLine(p1, p2, pathPaint);
        }
      }
    }
  }
}
