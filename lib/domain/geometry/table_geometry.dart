// Pure Dart Table Geometry & Coordinate Transformation Engine for Billiardlearning

import '../value_objects/value_objects.dart';

/// Pure Dart domain model representing table dimensions and coordinate transformations.
class TableGeometry {
  final double playfieldWidthMeters;
  final double playfieldLengthMeters;
  final double ballRadiusMeters;

  const TableGeometry({
    this.playfieldWidthMeters = 1.42,
    this.playfieldLengthMeters = 2.84,
    this.ballRadiusMeters = 0.03075, // 61.5mm standard Carom ball diameter / 2
  }) : assert(playfieldWidthMeters > 0, 'Playfield width must be positive'),
       assert(playfieldLengthMeters > 0, 'Playfield length must be positive'),
       assert(ballRadiusMeters > 0, 'Ball radius must be positive');

  /// Standard 3-Cushion Carom match table geometry (1.42m x 2.84m).
  static const caromMatchTable = TableGeometry(
    playfieldWidthMeters: 1.42,
    playfieldLengthMeters: 2.84,
    ballRadiusMeters: 0.03075,
  );

  /// Aspect ratio of length to width (typically 2.0 for standard Carom tables).
  double get aspectRatio => playfieldLengthMeters / playfieldWidthMeters;

  /// Converts a normalized [TablePoint] (u,v in [0,1]^2) to physical [WorldPoint] in meters.
  WorldPoint toWorldPoint(TablePoint point) {
    return WorldPoint(
      point.u * playfieldWidthMeters,
      point.v * playfieldLengthMeters,
    );
  }

  /// Converts a physical [WorldPoint] in meters to a normalized [TablePoint] (u,v).
  TablePoint toTablePoint(WorldPoint point) {
    return TablePoint(
      point.x / playfieldWidthMeters,
      point.y / playfieldLengthMeters,
    );
  }

  /// Calculates physical distance in meters between two normalized [TablePoint]s.
  ///
  /// Demonstrates aspect ratio non-uniformity (delta u != delta v physical distance).
  Vec2 tablePointDeltaToPhysicalMeters(double deltaU, double deltaV) {
    return Vec2(deltaU * playfieldWidthMeters, deltaV * playfieldLengthMeters);
  }

  /// Checks if a physical [WorldPoint] lies within playfield boundaries.
  bool isPointInsidePlayfield(WorldPoint point) {
    return point.x >= 0.0 &&
        point.x <= playfieldWidthMeters &&
        point.y >= 0.0 &&
        point.y <= playfieldLengthMeters;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableGeometry &&
          runtimeType == other.runtimeType &&
          playfieldWidthMeters == other.playfieldWidthMeters &&
          playfieldLengthMeters == other.playfieldLengthMeters &&
          ballRadiusMeters == other.ballRadiusMeters;

  @override
  int get hashCode =>
      playfieldWidthMeters.hashCode ^
      playfieldLengthMeters.hashCode ^
      ballRadiusMeters.hashCode;

  @override
  String toString() =>
      'TableGeometry(${playfieldWidthMeters}m x ${playfieldLengthMeters}m, ballRadius: ${ballRadiusMeters}m)';
}
