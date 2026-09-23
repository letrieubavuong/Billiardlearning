// Unit Tests for SceneEditorHitTester (Phase 4B)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/application/scene_editor/scene_editor_selection.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';
import 'package:libre2026/presentation/scene_editor/scene_editor_gesture_adapter.dart';
import 'package:libre2026/presentation/scene_editor/scene_editor_hit_tester.dart';
import 'package:libre2026/rendering/scene/scene_viewport.dart';

void main() {
  group('SceneEditorHitTester Priority & Orientation Tests', () {
    const adapter = SceneEditorGestureAdapter();
    const hitTester = SceneEditorHitTester();
    final now = DateTime.utc(2026, 9, 23);

    final testViewportVertical = SceneViewport(
      canvasSize: const Size(360.0, 720.0),
      viewMode: SceneViewMode.full,
      isVertical: true,
    );

    final testViewportHorizontal = SceneViewport(
      canvasSize: const Size(720.0, 360.0),
      viewMode: SceneViewMode.full,
      isVertical: false,
    );

    test('hit-test target priority order in pixel space', () {
      const pt = TablePoint(0.5, 0.5);

      final scene = BilliardScene(
        id: 'scene-1',
        name: 'Test Scene',
        balls: const [
          BallPosition(id: 'ball-1', ballType: 'red', position: pt),
        ],
        trajectories: const [
          TrajectoryLine(
            id: 'traj-1',
            colorHex: '#FFFFFF',
            points: [pt, TablePoint(0.8, 0.8)],
          ),
        ],
        annotations: const [
          SceneAnnotation(id: 'ann-1', text: 'Label', position: pt),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final hitScreenPos = adapter.tablePointToLocalOffset(
        pt,
        testViewportVertical,
        true,
      );

      // Trajectory Point (index 0) MUST win over Ball, Annotation, Trajectory Line
      final hit = hitTester.hitTest(
        hitScreenPos,
        scene,
        testViewportVertical,
        true,
      );
      expect(hit.type, equals(SceneEditorSelectionType.trajectoryPoint));
      expect(hit.targetId, equals('traj-1'));
      expect(hit.pointIndex, equals(0));
    });

    test('ball wins over annotation when trajectory point is not present', () {
      const pt = TablePoint(0.5, 0.5);

      final scene = BilliardScene(
        id: 'scene-1',
        name: 'Test Scene',
        balls: const [
          BallPosition(id: 'ball-1', ballType: 'red', position: pt),
        ],
        annotations: const [
          SceneAnnotation(id: 'ann-1', text: 'Label', position: pt),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final hitScreenPos = adapter.tablePointToLocalOffset(
        pt,
        testViewportVertical,
        true,
      );

      final hit = hitTester.hitTest(
        hitScreenPos,
        scene,
        testViewportVertical,
        true,
      );
      expect(hit.type, equals(SceneEditorSelectionType.ball));
      expect(hit.targetId, equals('ball-1'));
    });

    test(
      'horizontal mode hit testing resolves correct target at screen location',
      () {
        const pt = TablePoint(0.3, 0.3);

        final scene = BilliardScene(
          id: 'scene-1',
          name: 'Test Scene',
          balls: const [
            BallPosition(id: 'ball-h1', ballType: 'yellow', position: pt),
          ],
          createdAt: now,
          updatedAt: now,
        );

        final hitScreenPosHorizontal = adapter.tablePointToLocalOffset(
          pt,
          testViewportHorizontal,
          false,
        );

        final hit = hitTester.hitTest(
          hitScreenPosHorizontal,
          scene,
          testViewportHorizontal,
          false,
        );
        expect(hit.type, equals(SceneEditorSelectionType.ball));
        expect(hit.targetId, equals('ball-h1'));
      },
    );

    test('empty area returns selection none', () {
      final scene = BilliardScene(
        id: 'scene-1',
        name: 'Empty Scene',
        createdAt: now,
        updatedAt: now,
      );

      final centerOffset = adapter.tablePointToLocalOffset(
        const TablePoint(0.5, 0.5),
        testViewportVertical,
        true,
      );

      final hit = hitTester.hitTest(
        centerOffset,
        scene,
        testViewportVertical,
        true,
      );
      expect(hit.type, equals(SceneEditorSelectionType.none));
    });
  });
}
