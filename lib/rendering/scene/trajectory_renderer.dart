// Trajectory rendering component for Billiardlearning Phase 3

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/value_objects/value_objects.dart';
import 'scene_viewport.dart';
import 'scene_render_model.dart';

/// Legacy visual timing representation for progressive path rendering.
class PathTiming {
  final double startTime;
  final double endTime;

  const PathTiming(this.startTime, this.endTime);
}

/// Component responsible for drawing trajectory paths (solid or dashed),
/// computing visual timing fractions for progressive path playback, and
/// interpolating ball motion along path points.
class TrajectoryRenderer {
  const TrajectoryRenderer();

  /// Calculates total path length in normalized TablePoint units.
  double getPathLength(List<TablePoint> pts) {
    double len = 0.0;
    for (int i = 0; i < pts.length - 1; i++) {
      final double du = pts[i + 1].u - pts[i].u;
      final double dv = pts[i + 1].v - pts[i].v;
      len += math.sqrt(du * du + dv * dv);
    }
    return len;
  }

  /// Evaluates normalized position along a path given interpolation fraction [t] in [0, 1].
  TablePoint getPositionOnPath(List<TablePoint> points, double t) {
    if (points.isEmpty) return const TablePoint(0, 0);
    if (points.length == 1 || t <= 0.0) return points.first;
    if (t >= 1.0) return points.last;

    // Apply quadratic ease-out to simulate rolling friction deceleration
    final double easedT = t * (2.0 - t);

    double totalLength = 0.0;
    final List<double> segmentLengths = [];
    for (int i = 0; i < points.length - 1; i++) {
      final double du = points[i + 1].u - points[i].u;
      final double dv = points[i + 1].v - points[i].v;
      final double len = math.sqrt(du * du + dv * dv);
      segmentLengths.add(len);
      totalLength += len;
    }

    if (totalLength == 0.0) return points.first;

    final double targetDist = totalLength * easedT;
    double currentDist = 0.0;
    for (int i = 0; i < segmentLengths.length; i++) {
      if (currentDist + segmentLengths[i] >= targetDist) {
        final double segmentT = (targetDist - currentDist) / segmentLengths[i];
        final double u =
            points[i].u + (points[i + 1].u - points[i].u) * segmentT;
        final double v =
            points[i].v + (points[i + 1].v - points[i].v) * segmentT;
        return TablePoint(u, v);
      }
      currentDist += segmentLengths[i];
    }
    return points.last;
  }

  /// Returns progressive points up to fraction [t] in [0, 1].
  List<TablePoint> getProgressivePoints(List<TablePoint> points, double t) {
    if (points.isEmpty) return [];
    if (t >= 1.0) return points;

    final double easedT = t * (2.0 - t);

    double totalLength = 0.0;
    final List<double> segmentLengths = [];
    for (int i = 0; i < points.length - 1; i++) {
      final double du = points[i + 1].u - points[i].u;
      final double dv = points[i + 1].v - points[i].v;
      final double len = math.sqrt(du * du + dv * dv);
      segmentLengths.add(len);
      totalLength += len;
    }

    if (totalLength == 0.0) return [points.first];

    final double targetDist = totalLength * easedT;
    double currentDist = 0.0;
    final List<TablePoint> result = [points.first];

    for (int i = 0; i < segmentLengths.length; i++) {
      if (currentDist + segmentLengths[i] >= targetDist) {
        final double segmentT = (targetDist - currentDist) / segmentLengths[i];
        final double u =
            points[i].u + (points[i + 1].u - points[i].u) * segmentT;
        final double v =
            points[i].v + (points[i + 1].v - points[i].v) * segmentT;
        result.add(TablePoint(u, v));
        break;
      } else {
        result.add(points[i + 1]);
        currentDist += segmentLengths[i];
      }
    }
    return result;
  }

  /// Visual path sequence timing heuristics.
  List<PathTiming> computeTimings(List<TrajectoryRenderItem> paths) {
    final int n = paths.length;
    final List<double> lengths = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      lengths[i] = getPathLength(paths[i].points);
    }

    final List<int> parent = List.filled(n, -1);
    final List<double> colFraction = List.filled(n, 0.0);

    for (int i = 0; i < n; i++) {
      final TablePoint startPoint = paths[i].points.isNotEmpty
          ? paths[i].points.first
          : const TablePoint(0, 0);
      double earliestCollisionFraction = double.infinity;
      int bestParent = -1;

      for (int j = 0; j < n; j++) {
        if (i == j) continue;

        double currentDist = 0.0;
        for (int k = 0; k < paths[j].points.length - 1; k++) {
          final TablePoint A = paths[j].points[k];
          final TablePoint B = paths[j].points[k + 1];
          final double du = B.u - A.u;
          final double dv = B.v - A.v;
          final double segLen = math.sqrt(du * du + dv * dv);

          final double abLenSq = du * du + dv * dv;
          if (abLenSq > 0) {
            double u =
                ((startPoint.u - A.u) * du + (startPoint.v - A.v) * dv) /
                abLenSq;
            if (u < 0.0) u = 0.0;
            if (u > 1.0) u = 1.0;

            final TablePoint closest = TablePoint(A.u + u * du, A.v + u * dv);
            final double distU = startPoint.u - closest.u;
            final double distV = startPoint.v - closest.v;
            final double dist = math.sqrt(distU * distU + distV * distV);

            if (dist < 0.05) {
              final double hitDist = currentDist + u * segLen;
              final double frac = lengths[j] > 0 ? (hitDist / lengths[j]) : 0.0;
              if (frac < earliestCollisionFraction) {
                earliestCollisionFraction = frac;
                bestParent = j;
              }
            }
          }
          currentDist += segLen;
        }
      }

      if (bestParent != -1) {
        parent[i] = bestParent;
        colFraction[i] = earliestCollisionFraction;
      }
    }

    final List<double> startTimes = List.filled(n, 0.0);
    final List<bool> resolved = List.filled(n, false);

    for (int iter = 0; iter < n; iter++) {
      for (int i = 0; i < n; i++) {
        if (resolved[i]) continue;

        final int p = parent[i];
        if (p == -1) {
          startTimes[i] = 0.0;
          resolved[i] = true;
        } else if (resolved[p]) {
          final double parentLocalT = 1.0 - math.sqrt(1.0 - colFraction[i]);
          startTimes[i] = startTimes[p] + parentLocalT * (1.0 - startTimes[p]);
          resolved[i] = true;
        }
      }
    }

    for (int i = 0; i < n; i++) {
      if (!resolved[i]) {
        startTimes[i] = 0.0;
      }
    }

    final List<PathTiming> timings = [];
    for (int i = 0; i < n; i++) {
      timings.add(PathTiming(startTimes[i], 1.0));
    }
    return timings;
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
