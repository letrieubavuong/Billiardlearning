// Unit Tests for SceneEditorGestureAdapter (Phase 4B)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';
import 'package:libre2026/presentation/scene_editor/scene_editor_gesture_adapter.dart';
import 'package:libre2026/rendering/scene/legacy/legacy_render_adapter.dart';
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

    test(
      'exact bottom-rail contract table across all 8 view modes (Requirement 4)',
      () {
        final expectedBottomRailMap = <SceneViewMode, bool>{
          SceneViewMode.full: true,
          SceneViewMode.half: false,
          SceneViewMode.third: false,
          SceneViewMode.quarter: false,
          SceneViewMode.halfWidth: true,
          SceneViewMode.halfWidthHalfLength: false,
          SceneViewMode.halfWidthThirdLength: false,
          SceneViewMode.halfWidthQuarterLength: false,
        };

        for (final mode in SceneViewMode.values) {
          final scene = BilliardScene(
            id: 'test-scene',
            name: 'Test Scene',
            presentationConfig: ScenePresentationConfig(
              legacyViewTypeIndex: mode.index,
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final renderModel = LegacyRenderAdapter.sceneToRenderModel(
            scene: scene,
            isVertical: true,
          );

          expect(
            renderModel.hasBottomRail,
            equals(expectedBottomRailMap[mode]),
            reason: 'Bottom-rail contract failed for view mode $mode',
          );

          final viewport = SceneViewport(
            canvasSize: const Size(400, 800),
            viewMode: renderModel.viewMode,
            isVertical: renderModel.isVertical,
            hasBottomRail: renderModel.hasBottomRail,
          );

          expect(
            viewport.hasBottomRail,
            equals(expectedBottomRailMap[mode]),
            reason:
                'SceneViewport bottom-rail contract failed for view mode $mode',
          );
        }
      },
    );

    test(
      'detectRailRegion projects cushion rail taps to canonical edges and rejects middle taps',
      () {
        final viewport = SceneViewport(
          canvasSize: testCanvasSizeVertical,
          viewMode: SceneViewMode.full,
          isVertical: true,
        );

        // Top rail tap (above playfieldRect.top)
        final topRailOffset = Offset(viewport.playfieldRect.center.dx, 5.0);
        final topHit = adapter.detectRailRegion(topRailOffset, viewport, true);
        expect(topHit, isNotNull);
        expect(topHit!.side, equals('top'));
        expect(topHit.projectedPoint.v, equals(0.0));

        // Bottom rail tap (below playfieldRect.bottom)
        final bottomRailOffset = Offset(
          viewport.playfieldRect.center.dx,
          viewport.canvasSize.height - 5.0,
        );
        final bottomHit = adapter.detectRailRegion(
          bottomRailOffset,
          viewport,
          true,
        );
        expect(bottomHit, isNotNull);
        expect(bottomHit!.side, equals('bottom'));
        expect(bottomHit.projectedPoint.v, equals(1.0));

        // Left rail tap (left of playfieldRect.left)
        final leftRailOffset = Offset(5.0, viewport.playfieldRect.center.dy);
        final leftHit = adapter.detectRailRegion(
          leftRailOffset,
          viewport,
          true,
        );
        expect(leftHit, isNotNull);
        expect(leftHit!.side, equals('left'));
        expect(leftHit.projectedPoint.u, equals(0.0));

        // Right rail tap (right of playfieldRect.right)
        final rightRailOffset = Offset(
          viewport.canvasSize.width - 5.0,
          viewport.playfieldRect.center.dy,
        );
        final rightHit = adapter.detectRailRegion(
          rightRailOffset,
          viewport,
          true,
        );
        expect(rightHit, isNotNull);
        expect(rightHit!.side, equals('right'));
        expect(rightHit.projectedPoint.u, equals(1.0));

        // Middle of table tap -> rejected!
        final middleOffset = viewport.playfieldRect.center;
        final middleHit = adapter.detectRailRegion(
          middleOffset,
          viewport,
          true,
        );
        expect(middleHit, isNull);
      },
    );

    test(
      'localOffsetToVisibleTablePoint clamps pointer to visible playfieldRect crop boundaries',
      () {
        // Half view mode: playfieldRect height is half of full table
        final halfViewport = SceneViewport(
          canvasSize: const Size(360.0, 360.0),
          viewMode: SceneViewMode.half,
          isVertical: true,
        );

        // Pointer dragged below visible bottom edge
        final offsetBelowCrop = Offset(
          halfViewport.playfieldRect.center.dx,
          halfViewport.canvasSize.height + 100.0,
        );

        final clampedPt = adapter.localOffsetToVisibleTablePoint(
          offsetBelowCrop,
          halfViewport,
          true,
        );

        // Should be clamped to the visible bottom crop edge (v = 0.5)
        expect(clampedPt.v, closeTo(0.5, 1e-4));
      },
    );
  });
}
