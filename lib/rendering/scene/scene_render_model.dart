// Render model DTOs and theme definitions for Billiardlearning Phase 3

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/value_objects/value_objects.dart';
import 'scene_viewport.dart';

/// Converts domain rotation angle in degrees to renderer radians.
double degreesToRadians(double degrees) {
  return degrees * math.pi / 180.0;
}

/// Converts hex string `#AARRGGBB` or `#RRGGBB` to Flutter [Color].
/// Fallbacks to [fallback] if input is invalid.
Color parseHexColor(String? hex, {Color fallback = Colors.white}) {
  if (hex == null || hex.isEmpty) return fallback;
  String cleanHex = hex.toUpperCase().replaceAll('#', '');
  if (cleanHex.length == 6) {
    cleanHex = 'FF$cleanHex';
  }
  if (cleanHex.length == 8) {
    final int? value = int.tryParse(cleanHex, radix: 16);
    if (value != null) {
      return Color(value);
    }
  }
  return fallback;
}

/// Theme configuration for table rendering, indicator colors, and felt styling.
class SceneRenderTheme {
  final Color clothColor;
  final Color cushionColor;
  final Color woodRailColor;
  final Color gridColor;
  final Color diamondColor;
  final Map<String, Color> indicatorColors;

  const SceneRenderTheme({
    this.clothColor = const Color(0xFF004D40), // Teal
    this.cushionColor = const Color(0xFF00332C),
    this.woodRailColor = const Color(0xFF3E2723), // Wood brown
    this.gridColor = const Color(0x2EFFFFFF), // White 18%
    this.diamondColor = const Color(0xCCFFFFFF), // White 80%
    this.indicatorColors = const {},
  });
}

/// Render DTO for a single billiard ball.
class BallRenderItem {
  final TablePoint position;
  final Color color;
  final double opacity;
  final bool isGhost;
  final bool isOutline;
  final int ballTypeIndex; // 0: full, 1: half, 2: numbered
  final double rotationInRadians;
  final String? text;

  const BallRenderItem({
    required this.position,
    required this.color,
    this.opacity = 1.0,
    this.isGhost = false,
    this.isOutline = false,
    this.ballTypeIndex = 0,
    this.rotationInRadians = 0.0,
    this.text,
  });
}

/// Render DTO for a trajectory path.
class TrajectoryRenderItem {
  final List<TablePoint> points;
  final Color color;
  final double opacity;
  final bool isDashed;
  final String? role;

  const TrajectoryRenderItem({
    required this.points,
    this.color = const Color(0xB3FFFFFF),
    this.opacity = 1.0,
    this.isDashed = true,
    this.role,
  });
}

/// Render DTO for text annotation.
class AnnotationRenderItem {
  final TablePoint position;
  final String text;
  final Color color;
  final double fontSize;
  final double rotationInRadians;
  final String? role;

  const AnnotationRenderItem({
    required this.position,
    required this.text,
    this.color = Colors.white,
    this.fontSize = 12.0,
    this.rotationInRadians = 0.0,
    this.role,
  });
}

/// Render DTO for angle indicator arc.
class AngleRenderItem {
  final TablePoint a;
  final TablePoint b;
  final TablePoint c;
  final double radius;
  final Color color;
  final String? label;
  final String? role;

  const AngleRenderItem({
    required this.a,
    required this.b,
    required this.c,
    this.radius = 20.0,
    this.color = Colors.yellowAccent,
    this.label,
    this.role,
  });
}

/// Render DTO for cue ball effet mini-diagram.
class EffetRenderData {
  final List<Map<String, dynamic>> spots;
  final bool showHitBall;
  final int hitThickness;
  final String hitSide;
  final double spotSize;

  const EffetRenderData({
    this.spots = const [],
    this.showHitBall = false,
    this.hitThickness = 6,
    this.hitSide = 'right',
    this.spotSize = 25.0,
  });
}

/// Complete immutable rendering input for [ScenePainter].
class SceneRenderModel {
  final List<BallRenderItem> balls;
  final List<TrajectoryRenderItem> trajectories;
  final List<AnnotationRenderItem> annotations;
  final List<AngleRenderItem> angles;
  final SceneViewMode viewMode;
  final int diagramSystemIndex; // 0: standard, 1: diamond, 2: short3Cushion...
  final bool isVertical;
  final bool hasBottomRail;
  final double animationProgress;
  final SceneRenderTheme theme;
  final EffetRenderData? effetData;

  const SceneRenderModel({
    this.balls = const [],
    this.trajectories = const [],
    this.annotations = const [],
    this.angles = const [],
    this.viewMode = SceneViewMode.full,
    this.diagramSystemIndex = 0,
    this.isVertical = true,
    this.hasBottomRail = true,
    this.animationProgress = 1.0,
    this.theme = const SceneRenderTheme(),
    this.effetData,
  });
}
