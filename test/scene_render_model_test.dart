// Unit tests for SceneRenderModel helper functions and LegacyPlaybackCompatibility in Phase 3

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';
import 'package:libre2026/rendering/scene/scene_render_model.dart';
import 'package:libre2026/rendering/scene/legacy/legacy_render_adapter.dart';
import 'package:libre2026/rendering/scene/legacy/legacy_playback_compatibility.dart';
import 'package:libre2026/widgets/billiard_diagram.dart' as legacy;

void main() {
  group('SceneRenderModel Helpers', () {
    test('degreesToRadians converts degrees accurately', () {
      expect(degreesToRadians(0), equals(0.0));
      expect(degreesToRadians(90), closeTo(math.pi / 2, 1e-6));
      expect(degreesToRadians(180), closeTo(math.pi, 1e-6));
      expect(degreesToRadians(360), closeTo(2 * math.pi, 1e-6));
    });

    test('parseHexColor converts hex string #AARRGGBB to Color', () {
      final Color red = parseHexColor('#FF0000');
      expect(red.r, equals(1.0));
      expect(red.g, equals(0.0));
      expect(red.b, equals(0.0));
      expect(red.a, equals(1.0));

      final Color semiRed = parseHexColor('#80FF0000');
      expect(semiRed.r, equals(1.0));
      expect(semiRed.a, closeTo(0.5, 0.01));
    });

    test('parseHexColor returns fallback for invalid hex strings', () {
      final Color fallback = const Color(0xFF00FF00);
      expect(parseHexColor(null, fallback: fallback), equals(fallback));
      expect(parseHexColor('', fallback: fallback), equals(fallback));
      expect(parseHexColor('invalid', fallback: fallback), equals(fallback));
    });
  });

  group('Legacy Coordinate Conversion', () {
    test('Ball.at(2, 6) maps to TablePoint(u = 0.5, v = 0.75)', () {
      final legacyBall = legacy.Ball.at(2, 6, Colors.white);
      final pt = LegacyRenderAdapter.legacyRelativeToTablePoint(
        legacyBall.position,
      );

      expect(pt.u, closeTo(0.5, 1e-6));
      expect(pt.v, closeTo(0.75, 1e-6));
    });

    test(
      'diamonds path (0,0) and (4,8) map to TablePoint(0,0) and TablePoint(1,1)',
      () {
        final legacyPath = legacy.BallPath.diamonds(
          points: const [Offset(0, 0), Offset(4, 8)],
        );

        final pt1 = LegacyRenderAdapter.legacyRelativeToTablePoint(
          legacyPath.points.first,
        );
        final pt2 = LegacyRenderAdapter.legacyRelativeToTablePoint(
          legacyPath.points.last,
        );

        expect(pt1.u, closeTo(0.0, 1e-6));
        expect(pt1.v, closeTo(0.0, 1e-6));
        expect(pt2.u, closeTo(1.0, 1e-6));
        expect(pt2.v, closeTo(1.0, 1e-6));
      },
    );

    test('BilliardLabel at (2,4) maps to TablePoint(0.5, 0.5)', () {
      final legacyLabel = legacy.BilliardLabel.at(2, 4, 'Test');
      final pt = LegacyRenderAdapter.legacyRelativeToTablePoint(
        legacyLabel.position,
      );

      expect(pt.u, closeTo(0.5, 1e-6));
      expect(pt.v, closeTo(0.5, 1e-6));
    });

    test('BilliardAngle at (4,8) maps vertex b to TablePoint(1.0, 1.0)', () {
      final legacyAngle = legacy.BilliardAngle.at(
        a: const Offset(0, 0),
        b: const Offset(4, 8),
        c: const Offset(2, 4),
      );

      final ptB = LegacyRenderAdapter.legacyRelativeToTablePoint(legacyAngle.b);
      expect(ptB.u, closeTo(1.0, 1e-6));
      expect(ptB.v, closeTo(1.0, 1e-6));
    });
  });

  group('Legacy Playback Compatibility Metric', () {
    test('equal diamond lengths yield equal legacy visual distance metric', () {
      // Horizontal 2-diamond span: (0,0) to (0.5, 0)
      const hSegment1 = TablePoint(0, 0);
      const hSegment2 = TablePoint(0.5, 0);

      // Vertical 2-diamond span: (0,0) to (0, 0.25)
      const vSegment1 = TablePoint(0, 0);
      const vSegment2 = TablePoint(0, 0.25);

      final hDist = LegacyPlaybackCompatibility.distance(hSegment1, hSegment2);
      final vDist = LegacyPlaybackCompatibility.distance(vSegment1, vSegment2);

      expect(hDist, closeTo(0.5, 1e-6));
      expect(vDist, closeTo(0.5, 1e-6));
      expect(hDist, equals(vDist));
    });
  });
}
