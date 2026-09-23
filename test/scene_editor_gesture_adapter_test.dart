// Unit Tests for SceneEditorGestureAdapter (Phase 4B)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';
import 'package:libre2026/presentation/scene_editor/scene_editor_gesture_adapter.dart';
import 'package:libre2026/rendering/scene/scene_viewport.dart';

void main() {
  group('SceneEditorGestureAdapter Round-Trip & Orientation Tests', () {
    const adapter = SceneEditorGestureAdapter();

    const testCanvasSizeVertical = Size(360.0, 720.0);
    const testCanvasSizeHorizontal = Size(720.0, 360.0);

    const testTablePoints = [
      TablePoint(0.0, 0.0),
      TablePoint(0.5, 0.5),
      TablePoint(1.0, 1.0),
      TablePoint(0.25, 0.75),
    ];

    const viewModes = SceneViewMode.values;

    for (final mode in viewModes) {
      test('vertical round-trip mapping for viewMode $mode', () {
        final viewport = SceneViewport(
          canvasSize: testCanvasSizeVertical,
          viewMode: mode,
          isVertical: true,
        );

        for (final pt in testTablePoints) {
          final localOffset = adapter.tablePointToLocalOffset(
            pt,
            viewport,
            true,
          );
          final roundTripPt = adapter.localOffsetToTablePoint(
            localOffset,
            viewport,
            true,
          );

          expect(roundTripPt.u, closeTo(pt.u, 1e-4));
          expect(roundTripPt.v, closeTo(pt.v, 1e-4));
        }
      });

      test('horizontal round-trip mapping for viewMode $mode', () {
        final viewport = SceneViewport(
          canvasSize: testCanvasSizeHorizontal,
          viewMode: mode,
          isVertical: false,
        );

        for (final pt in testTablePoints) {
          final localOffset = adapter.tablePointToLocalOffset(
            pt,
            viewport,
            false,
          );
          final roundTripPt = adapter.localOffsetToTablePoint(
            localOffset,
            viewport,
            false,
          );

          expect(roundTripPt.u, closeTo(pt.u, 1e-4));
          expect(roundTripPt.v, closeTo(pt.v, 1e-4));
        }
      });
    }

    test('isPointInVisibleBounds filters taps outside playfield correctly', () {
      final viewport = SceneViewport(
        canvasSize: testCanvasSizeVertical,
        viewMode: SceneViewMode.full,
        isVertical: true,
      );

      // Playfield center point (inside)
      final centerOffset = viewport.tablePointToOffset(
        const TablePoint(0.5, 0.5),
      );
      expect(
        adapter.isPointInVisibleBounds(centerOffset, viewport, true),
        isTrue,
      );

      // Wood rail point (outside playfield, but inside rail canvas)
      final railOffset = const Offset(5.0, 5.0); // Inside wood rail
      expect(
        adapter.isPointInVisibleBounds(railOffset, viewport, true),
        isFalse,
      );
      expect(
        adapter.isPointInVisibleBounds(
          railOffset,
          viewport,
          true,
          isRailTool: true,
        ),
        isTrue,
      );

      // Outside canvas entirely
      final outsideOffset = const Offset(-50.0, -50.0);
      expect(
        adapter.isPointInVisibleBounds(outsideOffset, viewport, true),
        isFalse,
      );
      expect(
        adapter.isPointInVisibleBounds(
          outsideOffset,
          viewport,
          true,
          isRailTool: true,
        ),
        isFalse,
      );
    });
  });
}
