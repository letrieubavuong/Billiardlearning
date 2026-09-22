// LEGACY VISUAL PLAYBACK COMPATIBILITY - NOT PHYSICS
//
// Component handling visual path interpolation, legacy distance metrics,
// and progressive trail timings for backwards compatibility.

import 'dart:math' as math;
import '../../../domain/value_objects/value_objects.dart';
import '../scene_render_model.dart';

/// Legacy visual timing representation for progressive path rendering.
class PathTiming {
  final double startTime;
  final double endTime;

  const PathTiming(this.startTime, this.endTime);
}

/// Helper class for legacy visual playback compatibility metrics.
class LegacyPlaybackCompatibility {
  const LegacyPlaybackCompatibility();

  /// Calculates legacy visual distance between two [TablePoint]s:
  ///
  /// `dist = sqrt((u2 - u1)^2 + (2 * (v2 - v1))^2)`
  ///
  /// This accounts for the 1:2 aspect ratio of the 4x8 diamonds billiard table,
  /// ensuring horizontal 2-diamond spans and vertical 2-diamond spans yield equal metrics.
  static double distance(TablePoint p1, TablePoint p2) {
    final double du = p2.u - p1.u;
    final double dv = p2.v - p1.v;
    return math.sqrt(du * du + 4.0 * dv * dv);
  }

  /// Total path length using legacy 1:2 aspect ratio visual metric.
  static double getPathLength(List<TablePoint> pts) {
    double len = 0.0;
    for (int i = 0; i < pts.length - 1; i++) {
      len += distance(pts[i], pts[i + 1]);
    }
    return len;
  }

  /// Evaluates normalized position along a path given interpolation fraction [t] in [0, 1].
  static TablePoint getPositionOnPath(List<TablePoint> points, double t) {
    if (points.isEmpty) return const TablePoint(0, 0);
    if (points.length == 1 || t <= 0.0) return points.first;
    if (t >= 1.0) return points.last;

    // Apply quadratic ease-out to simulate rolling friction deceleration
    final double easedT = t * (2.0 - t);

    double totalLength = 0.0;
    final List<double> segmentLengths = [];
    for (int i = 0; i < points.length - 1; i++) {
      final double len = distance(points[i], points[i + 1]);
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
  static List<TablePoint> getProgressivePoints(List<TablePoint> points, double t) {
    if (points.isEmpty) return [];
    if (t >= 1.0) return points;

    final double easedT = t * (2.0 - t);

    double totalLength = 0.0;
    final List<double> segmentLengths = [];
    for (int i = 0; i < points.length - 1; i++) {
      final double len = distance(points[i], points[i + 1]);
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
  static List<PathTiming> computeTimings(List<TrajectoryRenderItem> paths) {
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
          final double segLen = distance(A, B);

          final double du = B.u - A.u;
          final double dv = (B.v - A.v) * 2.0;
          final double abLenSq = du * du + dv * dv;
          if (abLenSq > 0) {
            double u =
                ((startPoint.u - A.u) * du + (startPoint.v - A.v) * 2.0 * dv) /
                abLenSq;
            if (u < 0.0) u = 0.0;
            if (u > 1.0) u = 1.0;

            final TablePoint closest =
                TablePoint(A.u + u * du, A.v + u * (B.v - A.v));
            final double dist = distance(startPoint, closest);

            if (dist < 0.1) {
              final double hitDist = currentDist + u * segLen;
              final double frac =
                  lengths[j] > 0 ? (hitDist / lengths[j]) : 0.0;
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
}
