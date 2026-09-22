import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/geometry/table_geometry.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';

void main() {
  group('TableGeometry & Coordinate Transformations (Phase 2)', () {
    const geometry = TableGeometry.caromMatchTable;

    test('default Carom match table dimensions and aspect ratio', () {
      expect(geometry.playfieldWidthMeters, equals(1.42));
      expect(geometry.playfieldLengthMeters, equals(2.84));
      expect(geometry.ballRadiusMeters, equals(0.03075));
      expect(geometry.aspectRatio, closeTo(2.0, 0.0001));
    });

    test('TablePoint to WorldPoint mapping for key locations', () {
      expect(
        geometry.toWorldPoint(const TablePoint(0.0, 0.0)),
        equals(const WorldPoint(0.0, 0.0)),
      );

      expect(
        geometry.toWorldPoint(const TablePoint(1.0, 1.0)),
        equals(const WorldPoint(1.42, 2.84)),
      );

      expect(
        geometry.toWorldPoint(const TablePoint(0.5, 0.5)),
        equals(const WorldPoint(0.71, 1.42)),
      );
    });

    test('WorldPoint to TablePoint inverse mapping', () {
      expect(
        geometry.toTablePoint(const WorldPoint(0.0, 0.0)),
        equals(const TablePoint(0.0, 0.0)),
      );

      expect(
        geometry.toTablePoint(const WorldPoint(1.42, 2.84)),
        equals(const TablePoint(1.0, 1.0)),
      );

      expect(
        geometry.toTablePoint(const WorldPoint(0.71, 1.42)),
        equals(const TablePoint(0.5, 0.5)),
      );
    });

    test(
      'round-trip TablePoint -> WorldPoint -> TablePoint preserves coordinates',
      () {
        const originalPoints = [
          TablePoint(0.0, 0.0),
          TablePoint(1.0, 1.0),
          TablePoint(0.25, 0.75),
          TablePoint(0.333, 0.667),
        ];

        for (final orig in originalPoints) {
          final world = geometry.toWorldPoint(orig);
          final restored = geometry.toTablePoint(world);

          expect(restored.u, closeTo(orig.u, 0.0001));
          expect(restored.v, closeTo(orig.v, 0.0001));
        }
      },
    );

    test(
      'aspect ratio non-uniformity (delta u != delta v physical distance)',
      () {
        final delta = geometry.tablePointDeltaToPhysicalMeters(0.1, 0.1);

        // delta u = 0.1 -> 0.142m physical width
        expect(delta.x, closeTo(0.142, 0.0001));

        // delta v = 0.1 -> 0.284m physical length
        expect(delta.y, closeTo(0.284, 0.0001));

        expect(
          delta.x,
          isNot(equals(delta.y)),
          reason:
              'Physical delta along length is twice physical delta along width due to 1:2 aspect ratio',
        );
      },
    );

    test('playfield boundary check', () {
      expect(
        geometry.isPointInsidePlayfield(const WorldPoint(0.71, 1.42)),
        isTrue,
      );

      expect(
        geometry.isPointInsidePlayfield(const WorldPoint(-0.01, 1.42)),
        isFalse,
      );

      expect(
        geometry.isPointInsidePlayfield(const WorldPoint(1.43, 1.42)),
        isFalse,
      );
    });

    test('constructor asserts invalid non-positive dimensions', () {
      expect(
        () => TableGeometry(playfieldWidthMeters: 0.0),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => TableGeometry(playfieldLengthMeters: -2.84),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => TableGeometry(ballRadiusMeters: 0.0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
