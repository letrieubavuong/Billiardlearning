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

    test(
      'cropped view hit testing filters out hidden entities outside visible playfield (Requirement 15 & 16)',
      () {
        // 1. Half view mode (v in [0, 0.5] visible)
        final halfViewport = SceneViewport(
          canvasSize: const Size(360.0, 360.0),
          viewMode: SceneViewMode.half,
          isVertical: true,
        );

        // Ball at v = 0.55 is hidden below bottom crop edge
        final hiddenBallScene = BilliardScene(
          id: 'hidden-scene',
          name: 'Hidden Ball Scene',
          balls: const [
            BallPosition(
              id: 'hidden-ball',
              ballType: 'red',
              position: TablePoint(0.5, 0.55),
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );

        // Tap near bottom playfield edge
        final tapNearBottom = Offset(
          halfViewport.playfieldRect.center.dx,
          halfViewport.playfieldRect.bottom - 2.0,
        );

        final halfHit = hitTester.hitTest(
          tapNearBottom,
          hiddenBallScene,
          halfViewport,
          true,
        );
        expect(
          halfHit.type,
          equals(SceneEditorSelectionType.none),
          reason: 'Hidden ball at v=0.55 in half mode must NOT be hit!',
        );

        // 2. Third view mode (v in [0, 1/3] visible)
        final thirdViewport = SceneViewport(
          canvasSize: const Size(360.0, 300.0),
          viewMode: SceneViewMode.third,
          isVertical: true,
        );

        final hiddenThirdScene = BilliardScene(
          id: 'hidden-third',
          name: 'Hidden Third Scene',
          balls: const [
            BallPosition(
              id: 'ball-third',
              ballType: 'red',
              position: TablePoint(0.5, 0.40),
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );

        final thirdHit = hitTester.hitTest(
          tapNearBottom,
          hiddenThirdScene,
          thirdViewport,
          true,
        );
        expect(thirdHit.type, equals(SceneEditorSelectionType.none));

        // 3. Quarter view mode (v in [0, 0.25] visible)
        final quarterViewport = SceneViewport(
          canvasSize: const Size(360.0, 240.0),
          viewMode: SceneViewMode.quarter,
          isVertical: true,
        );

        final hiddenQuarterScene = BilliardScene(
          id: 'hidden-quarter',
          name: 'Hidden Quarter Scene',
          balls: const [
            BallPosition(
              id: 'ball-quarter',
              ballType: 'red',
              position: TablePoint(0.5, 0.30),
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );

        final quarterHit = hitTester.hitTest(
          tapNearBottom,
          hiddenQuarterScene,
          quarterViewport,
          true,
        );
        expect(quarterHit.type, equals(SceneEditorSelectionType.none));

        // 4. HalfWidth mode (u in [0, 0.5] visible)
        final halfWidthViewport = SceneViewport(
          canvasSize: const Size(200.0, 720.0),
          viewMode: SceneViewMode.halfWidth,
          isVertical: true,
        );

        final hiddenHalfWidthScene = BilliardScene(
          id: 'hidden-hw',
          name: 'Hidden HW Scene',
          balls: const [
            BallPosition(
              id: 'ball-hw',
              ballType: 'red',
              position: TablePoint(0.6, 0.5),
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );

        final tapNearRight = Offset(
          halfWidthViewport.playfieldRect.right - 2.0,
          halfWidthViewport.playfieldRect.center.dy,
        );

        final hwHit = hitTester.hitTest(
          tapNearRight,
          hiddenHalfWidthScene,
          halfWidthViewport,
          true,
        );
        expect(hwHit.type, equals(SceneEditorSelectionType.none));

        // 5. Horizontal mode half view hidden entity
        final halfHorizViewport = SceneViewport(
          canvasSize: const Size(360.0, 360.0),
          viewMode: SceneViewMode.half,
          isVertical: false,
        );

        final horizHit = hitTester.hitTest(
          tapNearBottom,
          hiddenBallScene,
          halfHorizViewport,
          false,
        );
        expect(horizHit.type, equals(SceneEditorSelectionType.none));
      },
    );

    test(
      'trajectory line segment clipping ensures invisible segments cannot be hit (Requirement 17)',
      () {
        final halfViewport = SceneViewport(
          canvasSize: const Size(360.0, 360.0),
          viewMode: SceneViewMode.half,
          isVertical: true,
        );

        // Trajectory segment fully in hidden lower table (v = 0.6 to 0.9)
        final hiddenTrajScene = BilliardScene(
          id: 'hidden-traj',
          name: 'Hidden Traj',
          trajectories: const [
            TrajectoryLine(
              id: 'traj-hidden',
              points: [TablePoint(0.5, 0.6), TablePoint(0.5, 0.9)],
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );

        final tapBottomEdge = Offset(
          halfViewport.playfieldRect.center.dx,
          halfViewport.playfieldRect.bottom - 2.0,
        );

        final hit = hitTester.hitTest(
          tapBottomEdge,
          hiddenTrajScene,
          halfViewport,
          true,
        );
        expect(
          hit.type,
          equals(SceneEditorSelectionType.none),
          reason: 'Fully hidden trajectory line segment must NOT be hit',
        );
      },
    );
  });
}
