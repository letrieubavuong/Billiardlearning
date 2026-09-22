// Pure Dart Value Objects for Billiardlearning Domain Foundation

import 'dart:math' as math;
import 'package:uuid/uuid.dart';

class Vec2 {
  final double x;
  final double y;

  const Vec2(this.x, this.y);

  static const zero = Vec2(0.0, 0.0);

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double scalar) => Vec2(x * scalar, y * scalar);
  Vec2 operator /(double scalar) => Vec2(x / scalar, y / scalar);

  double dot(Vec2 other) => x * other.x + y * other.y;
  double get length => math.sqrt(x * x + y * y);
  double get lengthSquared => x * x + y * y;

  Vec2 normalized() {
    final len = length;
    if (len == 0.0) return Vec2.zero;
    return Vec2(x / len, y / len);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vec2 &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Vec2($x, $y)';
}

class TablePoint {
  final double u;
  final double v;

  const TablePoint(this.u, this.v);

  bool get isWithinTable => u >= 0.0 && u <= 1.0 && v >= 0.0 && v <= 1.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TablePoint &&
          runtimeType == other.runtimeType &&
          u == other.u &&
          v == other.v;

  @override
  int get hashCode => u.hashCode ^ v.hashCode;

  @override
  String toString() => 'TablePoint(u: $u, v: $v)';
}

class WorldPoint {
  final double x;
  final double y;

  const WorldPoint(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'WorldPoint(x: $x, y: $y)';
}

class Angle {
  final double radians;

  const Angle.fromRadians(this.radians);
  factory Angle.fromDegrees(double degrees) =>
      Angle.fromRadians(degrees * (math.pi / 180.0));

  double get degrees => radians * (180.0 / math.pi);

  Angle normalized() {
    var r = radians % (2 * math.pi);
    if (r < 0) r += 2 * math.pi;
    return Angle.fromRadians(r);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Angle &&
          runtimeType == other.runtimeType &&
          radians == other.radians;

  @override
  int get hashCode => radians.hashCode;

  @override
  String toString() => 'Angle(${degrees.toStringAsFixed(1)}°)';
}

class StableId {
  final String value;

  const StableId(this.value);

  static const _uuid = Uuid();

  /// Generates a standard UUID v4 string identifier.
  static String generate() => _uuid.v4();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StableId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
