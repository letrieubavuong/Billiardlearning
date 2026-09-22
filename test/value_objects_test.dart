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

    test('zero vector normalization handles division by zero safely', () {
      final normZero = Vec2.zero.normalized();
      expect(normZero, equals(Vec2.zero));
      expect(normZero.length, 0.0);
    });

    test('equality and hash code', () {
      const v1 = Vec2(2.5, -1.0);
      const v2 = Vec2(2.5, -1.0);
      const v3 = Vec2(2.5, 1.0);

      expect(v1, equals(v2));
      expect(v1.hashCode, equals(v2.hashCode));
      expect(v1, isNot(equals(v3)));
    });
  });

  group('TablePoint and WorldPoint', () {
    test('TablePoint validates normalized range [0,1]x[0,1] boundaries', () {
      expect(const TablePoint(0.0, 0.0).isWithinTable, isTrue);
      expect(const TablePoint(1.0, 1.0).isWithinTable, isTrue);
      expect(const TablePoint(0.5, 0.5).isWithinTable, isTrue);

      expect(const TablePoint(-0.1, 0.5).isWithinTable, isFalse);
      expect(const TablePoint(1.1, 0.5).isWithinTable, isFalse);
      expect(const TablePoint(0.5, -0.1).isWithinTable, isFalse);
      expect(const TablePoint(0.5, 1.01).isWithinTable, isFalse);
    });

    test('WorldPoint equality, hashCode and toString semantics', () {
      const wp1 = WorldPoint(1.42, 2.84);
      const wp2 = WorldPoint(1.42, 2.84);
      const wp3 = WorldPoint(2.00, 1.00);

      expect(wp1, equals(wp2));
      expect(wp1.hashCode, equals(wp2.hashCode));
      expect(wp1, isNot(equals(wp3)));
      expect(wp1.toString(), 'WorldPoint(x: 1.42, y: 2.84)');
    });
  });

  group('Angle', () {
    test('converts degrees to radians and vice versa', () {
      final a = Angle.fromDegrees(180.0);
      expect(a.radians, closeTo(math.pi, 0.0001));
      expect(a.degrees, closeTo(180.0, 0.0001));
    });

    test('normalizes positive overflow and negative angles', () {
      final overflow = Angle.fromDegrees(450.0).normalized();
      expect(overflow.degrees, closeTo(90.0, 0.0001));

      final negative = Angle.fromDegrees(-90.0).normalized();
      expect(negative.degrees, closeTo(270.0, 0.0001));
    });
  });

  group('StableId', () {
    test('generates valid UUID v4 formatted strings', () {
      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      );

      final id = StableId.generate();
      expect(id, isNotEmpty);
      expect(
        uuidRegex.hasMatch(id),
        isTrue,
        reason: 'Generated ID $id must match standard UUID v4 format',
      );
      expect(
        id.startsWith('id_'),
        isFalse,
        reason: 'Legacy timestamp format id_ must not be used',
      );
    });

    test('uniqueness sample test generating 1000 UUIDs', () {
      const sampleCount = 1000;
      final ids = <String>{};

      for (var i = 0; i < sampleCount; i++) {
        ids.add(StableId.generate());
      }

      expect(ids.length, equals(sampleCount));
    });
  });
}
