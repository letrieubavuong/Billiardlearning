// Unit tests for SceneViewport coordinate transforms in Phase 3

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';
import 'package:libre2026/rendering/scene/scene_viewport.dart';

void main() {
  group('SceneViewport Coordinate Transforms', () {
    // Standard full canvas size matching 1:2 playfield aspect ratio + rails (W=400, H=722.58)
    const double totalR = 400.0 * (12.0 / 124.0); // 38.709677
    const double pWidth = 400.0 - 2 * totalR; // 322.580645
    const double pHeight = 2 * pWidth; // 645.16129
    const Size fullCanvasSize = Size(400.0, totalR + pHeight + totalR);

    test('TablePoint(0,0) maps to playfield top-left Offset', () {
      final viewport = SceneViewport(canvasSize: fullCanvasSize);
      final Offset offset = viewport.tablePointToOffset(const TablePoint(0, 0));

      expect(offset.dx, equals(viewport.playfieldRect.left));
      expect(offset.dy, equals(viewport.playfieldRect.top));
    });

    test('TablePoint(1,1) maps to full table bottom-right Offset in full mode', () {
      final viewport = SceneViewport(canvasSize: fullCanvasSize);
      final Offset offset = viewport.tablePointToOffset(const TablePoint(1, 1));

      expect(offset.dx, closeTo(viewport.playfieldRect.right, 1e-5));
      expect(offset.dy, closeTo(viewport.playfieldRect.bottom, 1e-5));
    });

    test('TablePoint(0.5, 0.5) maps to playfield center Offset in full mode', () {
      final viewport = SceneViewport(canvasSize: fullCanvasSize);
      final Offset offset = viewport.tablePointToOffset(const TablePoint(0.5, 0.5));

      expect(offset.dx, closeTo(viewport.playfieldRect.center.dx, 1e-5));
      expect(offset.dy, closeTo(viewport.playfieldRect.center.dy, 1e-5));
    });

    test('offsetToTablePoint is inverse of tablePointToOffset across all view modes', () {
      for (final mode in SceneViewMode.values) {
        final viewport = SceneViewport(
          canvasSize: fullCanvasSize,
          viewMode: mode,
        );
        const originalPt = TablePoint(0.25, 0.75);

        final Offset offset = viewport.tablePointToOffset(originalPt);
        final TablePoint mappedPt = viewport.offsetToTablePoint(offset);

        expect(
          mappedPt.u,
          closeTo(originalPt.u, 1e-6),
          reason: 'Failed u round-trip for view mode $mode',
        );
        expect(
          mappedPt.v,
          closeTo(originalPt.v, 1e-6),
          reason: 'Failed v round-trip for view mode $mode',
        );
      }
    });

    test('full view mode visible bottom-right is TablePoint(1, 1)', () {
      final viewport = SceneViewport(
        canvasSize: const Size(400.0, totalR + 8 * (pWidth / 4) + totalR),
        viewMode: SceneViewMode.full,
        hasBottomRail: true,
      );
      final offset = viewport.tablePointToOffset(const TablePoint(1, 1));
      expect(offset.dx, closeTo(viewport.playfieldRect.right, 1e-5));
      expect(offset.dy, closeTo(viewport.playfieldRect.bottom, 1e-5));
    });

    test('half view mode visible bottom-right is TablePoint(1, 0.5)', () {
      final viewport = SceneViewport(
        canvasSize: const Size(400.0, totalR + 4 * (pWidth / 4)),
        viewMode: SceneViewMode.half,
        hasBottomRail: false,
      );
      final offset = viewport.tablePointToOffset(const TablePoint(1, 0.5));
      expect(offset.dx, closeTo(viewport.playfieldRect.right, 1e-5));
      expect(offset.dy, closeTo(viewport.playfieldRect.bottom, 1e-5));
    });

    test('third view mode visible bottom-right is TablePoint(1, 0.375)', () {
      final viewport = SceneViewport(
        canvasSize: const Size(400.0, totalR + 3 * (pWidth / 4)),
        viewMode: SceneViewMode.third,
        hasBottomRail: false,
      );
      final offset = viewport.tablePointToOffset(const TablePoint(1, 0.375));
      expect(offset.dx, closeTo(viewport.playfieldRect.right, 1e-5));
      expect(offset.dy, closeTo(viewport.playfieldRect.bottom, 1e-5));
    });

    test('quarter view mode visible bottom-right is TablePoint(1, 0.25)', () {
      final viewport = SceneViewport(
        canvasSize: const Size(400.0, totalR + 2 * (pWidth / 4)),
        viewMode: SceneViewMode.quarter,
        hasBottomRail: false,
      );
      final offset = viewport.tablePointToOffset(const TablePoint(1, 0.25));
      expect(offset.dx, closeTo(viewport.playfieldRect.right, 1e-5));
      expect(offset.dy, closeTo(viewport.playfieldRect.bottom, 1e-5));
    });

    test('halfWidth view mode visible bottom-right is TablePoint(0.5, 1)', () {
      // W=200, hasRightRail=false => denom=62 => totalR = 200 * (12/62) = 38.709677
      // pW = 200 - 38.709677 = 161.290322 => spacing = 161.290322 / 2 = 80.645161 (same!)
      const double rHalf = 200.0 * (12.0 / 62.0);
      const double pWHalf = 200.0 - rHalf;
      final viewport = SceneViewport(
        canvasSize: const Size(200.0, rHalf + 8 * (pWHalf / 2) + rHalf),
        viewMode: SceneViewMode.halfWidth,
        hasBottomRail: true,
      );
      final offset = viewport.tablePointToOffset(const TablePoint(0.5, 1));
      expect(offset.dx, closeTo(viewport.playfieldRect.right, 1e-5));
      expect(offset.dy, closeTo(viewport.playfieldRect.bottom, 1e-5));
    });

    test('halfWidthHalfLength view mode visible bottom-right is TablePoint(0.5, 0.5)', () {
      const double rHalf = 200.0 * (12.0 / 62.0);
      const double pWHalf = 200.0 - rHalf;
      final viewport = SceneViewport(
        canvasSize: const Size(200.0, rHalf + 4 * (pWHalf / 2)),
        viewMode: SceneViewMode.halfWidthHalfLength,
        hasBottomRail: false,
      );
      final offset = viewport.tablePointToOffset(const TablePoint(0.5, 0.5));
      expect(offset.dx, closeTo(viewport.playfieldRect.right, 1e-5));
      expect(offset.dy, closeTo(viewport.playfieldRect.bottom, 1e-5));
    });

    test('halfWidthThirdLength view mode visible bottom-right is TablePoint(0.5, 0.375)', () {
      const double rHalf = 200.0 * (12.0 / 62.0);
      const double pWHalf = 200.0 - rHalf;
      final viewport = SceneViewport(
        canvasSize: const Size(200.0, rHalf + 3 * (pWHalf / 2)),
        viewMode: SceneViewMode.halfWidthThirdLength,
        hasBottomRail: false,
      );
      final offset = viewport.tablePointToOffset(const TablePoint(0.5, 0.375));
      expect(offset.dx, closeTo(viewport.playfieldRect.right, 1e-5));
      expect(offset.dy, closeTo(viewport.playfieldRect.bottom, 1e-5));
    });

    test('halfWidthQuarterLength view mode visible bottom-right is TablePoint(0.5, 0.25)', () {
      const double rHalf = 200.0 * (12.0 / 62.0);
      const double pWHalf = 200.0 - rHalf;
      final viewport = SceneViewport(
        canvasSize: const Size(200.0, rHalf + 2 * (pWHalf / 2)),
        viewMode: SceneViewMode.halfWidthQuarterLength,
        hasBottomRail: false,
      );
      final offset = viewport.tablePointToOffset(const TablePoint(0.5, 0.25));
      expect(offset.dx, closeTo(viewport.playfieldRect.right, 1e-5));
      expect(offset.dy, closeTo(viewport.playfieldRect.bottom, 1e-5));
    });
  });
}
