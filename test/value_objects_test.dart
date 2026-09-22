import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';

void main() {
  group('Vec2 Value Object', () {
    test(
      'vector addition, subtraction, scalar multiplication and division',
      () {
        const v1 = Vec2(3.0, 4.0);
        const v2 = Vec2(1.0, 2.0);

        expect(v1 + v2, const Vec2(4.0, 6.0));
        expect(v1 - v2, const Vec2(2.0, 2.0));
        expect(v1 * 2.0, const Vec2(6.0, 8.0));
        expect(v1 / 2.0, const Vec2(1.5, 2.0));
      },
    );

    test('dot product and length calculations', () {
      const v = Vec2(3.0, 4.0);
      expect(v.length, 5.0);
      expect(v.lengthSquared, 25.0);

      const u = Vec2(2.0, 0.0);
      expect(v.dot(u), 6.0);

      final norm = v.normalized();
      expect(norm.x, closeTo(0.6, 0.0001));
      expect(norm.y, closeTo(0.8, 0.0001));
      expect(norm.length, closeTo(1.0, 0.0001));
    });
  });

  group('TablePoint and WorldPoint', () {
    test('TablePoint validates normalized range [0,1]x[0,1]', () {
      const p1 = TablePoint(0.5, 0.5);
      expect(p1.isWithinTable, isTrue);

      const p2 = TablePoint(1.2, 0.5);
      expect(p2.isWithinTable, isFalse);
    });

    test('WorldPoint equality and format', () {
      const wp1 = WorldPoint(1.42, 2.84);
      const wp2 = WorldPoint(1.42, 2.84);
      expect(wp1, wp2);
    });
  });

  group('Angle', () {
    test('converts degrees to radians and vice versa', () {
      final a = Angle.fromDegrees(180.0);
      expect(a.radians, closeTo(math.pi, 0.0001));
      expect(a.degrees, closeTo(180.0, 0.0001));
    });

    test('normalizes angles', () {
      final a = Angle.fromDegrees(450.0).normalized();
      expect(a.degrees, closeTo(90.0, 0.0001));
    });
  });

  group('StableId', () {
    test('generates unique stable string IDs', () {
      final id1 = StableId.generate();
      final id2 = StableId.generate();
      expect(id1, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });
  });
}
