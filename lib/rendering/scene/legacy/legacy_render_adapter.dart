// Legacy rendering adapter for Billiardlearning Phase 3

import 'package:flutter/material.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/value_objects/value_objects.dart';
import '../scene_render_model.dart';
import '../scene_viewport.dart';
import '../../../widgets/billiard_diagram.dart' as legacy;

/// Adapter mapping domain [BilliardScene] and legacy widget diagram objects
/// to new modular [SceneRenderModel] DTOs.
class LegacyRenderAdapter {
  const LegacyRenderAdapter();

  /// Converts legacy relative Offset(dx, dy) where dx = xDiamond/4 and dy = yDiamond/4
  /// to canonical TablePoint(u, v) where u = xDiamond/4 and v = yDiamond/8.
  static TablePoint legacyRelativeToTablePoint(Offset p) {
    return TablePoint(p.dx, p.dy / 2.0);
  }

  /// Converts a domain [BilliardScene] into a modular [SceneRenderModel].
  static SceneRenderModel sceneToRenderModel({
    required BilliardScene scene,
    double animationProgress = 1.0,
    Map<String, Color>? themeIndicatorColors,
    Map<String, dynamic>? effetData,
    bool isVertical = true,
  }) {
    final List<BallRenderItem> balls = scene.balls.map((b) {
      Color ballColor;
      if (b.colorHex != null && b.colorHex!.isNotEmpty) {
        ballColor = parseHexColor(b.colorHex, fallback: Colors.white);
      } else {
        switch (b.ballType) {
          case 'yellow':
            ballColor = Colors.yellow;
            break;
          case 'red':
            ballColor = Colors.red;
            break;
          case 'white':
          default:
            ballColor = Colors.white;
            break;
        }
      }

      final bool isGhost = b.ballType == 'ghost';

      int typeIndex;
      if (b.legacyType != null) {
        typeIndex = b.legacyType!;
      } else if (b.ballType == 'extra' &&
          b.label != null &&
          b.label!.isNotEmpty) {
        typeIndex = 2; // numbered ball
      } else {
        typeIndex = 0;
      }

      return BallRenderItem(
        position: b.position,
        color: ballColor,
        opacity: isGhost ? 0.5 : 1.0,
        isGhost: isGhost,
        isOutline: false,
        ballTypeIndex: typeIndex,
        rotationInRadians: degreesToRadians(b.rotation ?? 0.0),
        text: b.label,
      );
    }).toList();

    final List<TrajectoryRenderItem> trajectories = scene.trajectories.map((t) {
      return TrajectoryRenderItem(
        points: t.points,
        color: parseHexColor(t.colorHex, fallback: Colors.white70),
        opacity: 1.0,
        isDashed: true,
      );
    }).toList();

    final List<AnnotationRenderItem> annotations = scene.annotations.map((a) {
      return AnnotationRenderItem(
        position: a.position,
        text: a.text,
        color: parseHexColor(a.colorHex, fallback: Colors.white),
        fontSize: scene.presentationConfig?.labelFontSize ?? 12.0,
        rotationInRadians: degreesToRadians(a.rotation ?? 0.0),
        role: a.role,
      );
    }).toList();

    final int viewIndex = scene.presentationConfig?.legacyViewTypeIndex ?? 0;
    final SceneViewMode viewMode = SceneViewMode.values.elementAt(
      viewIndex.clamp(0, SceneViewMode.values.length - 1),
    );

    // Derive hasBottomRail from resolved viewMode
    final bool hasBottomRail =
        viewMode == SceneViewMode.full || viewMode == SceneViewMode.halfWidth;

    final int sysIndex = scene.presentationConfig?.legacySystemIndex ?? 0;

    EffetRenderData? effet;
    if (effetData != null) {
      effet = EffetRenderData(
        spots: effetData['spots'] != null
            ? List<Map<String, dynamic>>.from(effetData['spots'])
            : const [],
        showHitBall: effetData['showHitBall'] ?? false,
        hitThickness: effetData['hitThickness'] ?? 6,
        hitSide: effetData['hitSide'] ?? 'right',
        spotSize: (effetData['spotSize'] as num?)?.toDouble() ?? 25.0,
      );
    }

    return SceneRenderModel(
      balls: balls,
      trajectories: trajectories,
      annotations: annotations,
      viewMode: viewMode,
      diagramSystemIndex: sysIndex,
      isVertical: isVertical,
      hasBottomRail: hasBottomRail,
      animationProgress: animationProgress,
      theme: SceneRenderTheme(
        indicatorColors: themeIndicatorColors ?? const {},
      ),
      effetData: effet,
    );
  }

  /// Converts legacy `BilliardDiagram` parameters into a modular [SceneRenderModel].
  static SceneRenderModel legacyParametersToRenderModel({
    required List<legacy.Ball> balls,
    List<legacy.BallPath>? paths,
    List<legacy.BilliardLabel>? labels,
    List<legacy.BilliardAngle>? angles,
    legacy.DiagramSystem system = legacy.DiagramSystem.standard,
    legacy.TableViewType viewType = legacy.TableViewType.full,
    bool isVertical = false,
    bool hasBottomRail = true,
    double animationProgress = 1.0,
    Map<String, Color>? themeIndicatorColors,
    Map<String, dynamic>? effetData,
  }) {
    final ballItems = balls.map((b) {
      return BallRenderItem(
        position: legacyRelativeToTablePoint(b.position),
        color: b.color,
        opacity: b.opacity,
        isGhost: b.isGhost,
        isOutline: b.isOutline,
        ballTypeIndex: b.type.index,
        rotationInRadians: b.rotation, // Legacy Ball holds radians
        text: b.text,
      );
    }).toList();

    final trajectoryItems = (paths ?? []).map((p) {
      return TrajectoryRenderItem(
        points: p.points.map((pt) => legacyRelativeToTablePoint(pt)).toList(),
        color: p.color,
        opacity: p.opacity,
        isDashed: p.isDashed,
        role: p.role,
      );
    }).toList();

    final annotationItems = (labels ?? []).map((l) {
      return AnnotationRenderItem(
        position: legacyRelativeToTablePoint(l.position),
        text: l.text,
        color: l.color,
        fontSize: l.fontSize,
        rotationInRadians: l.rotation, // Legacy BilliardLabel holds radians
        role: l.role,
      );
    }).toList();

    final angleItems = (angles ?? []).map((a) {
      return AngleRenderItem(
        a: legacyRelativeToTablePoint(a.a),
        b: legacyRelativeToTablePoint(a.b),
        c: legacyRelativeToTablePoint(a.c),
        radius: a.radius,
        color: a.color,
        label: a.label,
        role: a.role,
      );
    }).toList();

    final SceneViewMode mode = SceneViewMode.values[viewType.index];

    EffetRenderData? effet;
    if (effetData != null) {
      effet = EffetRenderData(
        spots: effetData['spots'] != null
            ? List<Map<String, dynamic>>.from(effetData['spots'])
            : const [],
        showHitBall: effetData['showHitBall'] ?? false,
        hitThickness: effetData['hitThickness'] ?? 6,
        hitSide: effetData['hitSide'] ?? 'right',
        spotSize: (effetData['spotSize'] as num?)?.toDouble() ?? 25.0,
      );
    }

    return SceneRenderModel(
      balls: ballItems,
      trajectories: trajectoryItems,
      annotations: annotationItems,
      angles: angleItems,
      viewMode: mode,
      diagramSystemIndex: system.index,
      isVertical: isVertical,
      hasBottomRail: hasBottomRail,
      animationProgress: animationProgress,
      theme: SceneRenderTheme(
        indicatorColors: themeIndicatorColors ?? const {},
      ),
      effetData: effet,
    );
  }
}
