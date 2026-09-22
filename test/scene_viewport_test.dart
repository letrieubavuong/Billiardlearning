// Unit tests for SceneViewport coordinate transforms in Phase 3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';
import 'package:libre2026/rendering/scene/scene_viewport.dart';

void main() {
  group('SceneViewport Coordinate Transforms', () {
    const Size defaultCanvasSize = Size(400, 800);

    test('TablePoint(0,0) maps to playfield top-left Offset', () {
      final viewport = SceneViewport(canvasSize: defaultCanvasSize);
      final Offset offset = viewport.tablePointToOffset(const TablePoint(0, 0));

      expect(offset.dx, equals(viewport.playfieldRect.left));
      expect(offset.dy, equals(viewport.playfieldRect.top));
    });

    test('TablePoint(1,1) maps to playfield bottom-right Offset', () {
      final viewport = SceneViewport(canvasSize: defaultCanvasSize);
      final Offset offset = viewport.tablePointToOffset(const TablePoint(1, 1));

      expect(offset.dx, equals(viewport.playfieldRect.right));
      expect(offset.dy, equals(viewport.playfieldRect.bottom));
    });

    test('TablePoint(0.5, 0.5) maps to playfield center Offset', () {
      final viewport = SceneViewport(canvasSize: defaultCanvasSize);
      final Offset offset = viewport.tablePointToOffset(const TablePoint(0.5, 0.5));

      expect(offset.dx, closeTo(viewport.playfieldRect.center.dx, 1e-5));
      expect(offset.dy, closeTo(viewport.playfieldRect.center.dy, 1e-5));
    });

    test('offsetToTablePoint is inverse of tablePointToOffset', () {
      final viewport = SceneViewport(canvasSize: defaultCanvasSize);
      const originalPt = TablePoint(0.25, 0.75);

      final Offset offset = viewport.tablePointToOffset(originalPt);
      final TablePoint mappedPt = viewport.offsetToTablePoint(offset);

      expect(mappedPt.u, closeTo(originalPt.u, 1e-6));
      expect(mappedPt.v, closeTo(originalPt.v, 1e-6));
    });

    test('SceneViewMode halfWidth changes hSegments to 2', () {
      final viewportHalf = SceneViewport(
        canvasSize: defaultCanvasSize,
        viewMode: SceneViewMode.halfWidth,
      );

      expect(viewportHalf.hSegments, equals(2));
    });
  });
}
