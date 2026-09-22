import 'package:flutter/material.dart';

enum BallType { full, half, numbered }

class Ball {
  final Offset position; // Tọa độ (0-4 ngang, 0-8 dọc)
  final Color color;
  final double opacity;
  final bool isGhost;
  final bool isOutline;
  final BallType type;
  final double rotation;
  final String? text;

  static const double diameter = 0.172;

  Ball(
    this.position,
    this.color, {
    this.opacity = 1.0,
    this.isGhost = false,
    this.isOutline = false,
    this.type = BallType.full,
    this.rotation = 0,
    this.text,
  });

  static Ball at(
    double x,
    double y,
    Color color, {
    double opacity = 1.0,
    bool isGhost = false,
    bool isOutline = false,
    BallType type = BallType.full,
    double rotation = 0,
    String? text,
  }) {
    return Ball(
      Offset(x, y),
      color,
      opacity: opacity,
      isGhost: isGhost,
      isOutline: isOutline,
      type: type,
      rotation: rotation,
      text: text,
    );
  }
}

class BallPath {
  final List<Offset> points;
  final Color color;
  final double opacity;
  final bool isDashed;

  BallPath({
    required this.points,
    this.color = Colors.white70,
    this.opacity = 1.0,
    this.isDashed = true,
  });

  static BallPath diamonds({
    required List<Offset> points,
    Color color = Colors.white70,
    double opacity = 1.0,
    bool isDashed = true,
  }) {
    return BallPath(
      points: points,
      color: color,
      opacity: opacity,
      isDashed: isDashed,
    );
  }
}

class BilliardLabel {
  final Offset position;
  final String text;
  final Color color;
  final double fontSize;
  final double rotation;

  BilliardLabel(
    this.position,
    this.text, {
    this.color = Colors.white,
    this.fontSize = 12,
    this.rotation = 0,
  });

  static BilliardLabel at(
    double x,
    double y,
    String text, {
    Color color = Colors.white,
    double fontSize = 12,
    double rotation = 0,
  }) {
    return BilliardLabel(
      Offset(x, y),
      text,
      color: color,
      fontSize: fontSize,
      rotation: rotation,
    );
  }
}

class BilliardAngle {
  final Offset a, b, c;
  final double radius;
  final Color color;
  final String? label;

  BilliardAngle({
    required this.a,
    required this.b,
    required this.c,
    this.radius = 20,
    this.color = Colors.yellowAccent,
    this.label,
  });

  static BilliardAngle at({
    required Offset a,
    required Offset b,
    required Offset c,
    double radius = 20,
    Color color = Colors.yellowAccent,
    String? label,
  }) {
    return BilliardAngle(
      a: a,
      b: b,
      c: c,
      radius: radius,
      color: color,
      label: label,
    );
  }
}
