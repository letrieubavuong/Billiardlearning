// Unit tests for SceneRenderModel helper functions in Phase 3

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/rendering/scene/scene_render_model.dart';

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
      expect(red.red, equals(255));
      expect(red.green, equals(0));
      expect(red.blue, equals(0));
      expect(red.alpha, equals(255));

      final Color semiRed = parseHexColor('#80FF0000');
      expect(semiRed.red, equals(255));
      expect(semiRed.alpha, equals(0x80));
    });

    test('parseHexColor returns fallback for invalid hex strings', () {
      final Color fallback = const Color(0xFF00FF00);
      expect(parseHexColor(null, fallback: fallback), equals(fallback));
      expect(parseHexColor('', fallback: fallback), equals(fallback));
      expect(parseHexColor('invalid', fallback: fallback), equals(fallback));
    });
  });
}
