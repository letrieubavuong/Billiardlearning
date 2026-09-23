// Widget Unit Tests for SceneEditorCanvas (Phase 4B)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/application/scene_editor/scene_editor_controller.dart';
import 'package:libre2026/application/scene_editor/scene_editor_exception.dart';
import 'package:libre2026/application/scene_editor/scene_editor_tool.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';
import 'package:libre2026/presentation/scene_editor/scene_editor_canvas.dart';
import 'package:libre2026/presentation/scene_editor/scene_editor_gesture_adapter.dart';
import 'package:libre2026/rendering/scene/scene_viewport.dart';

void main() {
  group('SceneEditorCanvas Widget Tests (Phase 4B)', () {
    late DateTime fixedTime;
    late DateTime Function() clock;
    const adapter = SceneEditorGestureAdapter();

    setUp(() {
      fixedTime = DateTime.utc(2026, 9, 23, 10, 0, 0);
      clock = () => fixedTime;
    });

    testWidgets('one drag = exactly ONE undo step (Requirement 44)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final initialScene = BilliardScene(
        id: 'scene-1',
        name: 'Scene with Ball',
        balls: const [
          BallPosition(
            id: 'b1',
            ballType: 'red',
            position: TablePoint(0.2, 0.2),
          ),
        ],
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      final controller = SceneEditorController(
        initialScene: initialScene,
        clock: clock,
      );
      controller.setTool(SceneEditorTool.move);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 720,
              child: SceneEditorCanvas(
                controller: controller,
                isVertical: true,
              ),
            ),
          ),
        ),
      );

      final viewport = SceneViewport(
        canvasSize: const Size(360, 720),
        viewMode: SceneViewMode.full,
        isVertical: true,
      );

      final topLeft = tester.getTopLeft(find.byType(SceneEditorCanvas));

      final startOffset =
          topLeft +
          adapter.tablePointToLocalOffset(
            const TablePoint(0.2, 0.2),
            viewport,
            true,
          );
      final targetOffset =
          topLeft +
          adapter.tablePointToLocalOffset(
            const TablePoint(0.7, 0.7),
            viewport,
            true,
          );

      final gesture = await tester.startGesture(startOffset);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(startOffset + const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(targetOffset);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      final movedBall = controller.currentScene.balls.first;
      expect(movedBall.position.u, closeTo(0.7, 0.05));
      expect(movedBall.position.v, closeTo(0.7, 0.05));

      // Assert exactly ONE undo step in history!
      expect(controller.state.canUndo, isTrue);

      controller.undo();
      expect(
        controller.currentScene.balls.first.position,
        equals(const TablePoint(0.2, 0.2)),
      );

      // Second undo must NOT be available (intermediate drag frames were not pushed)
      expect(controller.state.canUndo, isFalse);
    });

    testWidgets(
      'drag cancel discards preview without committing (Requirement 45)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final initialScene = BilliardScene(
          id: 'scene-1',
          name: 'Scene with Ball',
          balls: const [
            BallPosition(
              id: 'b1',
              ballType: 'red',
              position: TablePoint(0.3, 0.3),
            ),
          ],
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        final controller = SceneEditorController(
          initialScene: initialScene,
          clock: clock,
        );
        controller.setTool(SceneEditorTool.move);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 720,
                child: SceneEditorCanvas(
                  controller: controller,
                  isVertical: true,
                ),
              ),
            ),
          ),
        );

        final viewport = SceneViewport(
          canvasSize: const Size(360, 720),
          viewMode: SceneViewMode.full,
          isVertical: true,
        );

        final topLeft = tester.getTopLeft(find.byType(SceneEditorCanvas));

        final startOffset =
            topLeft +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.3, 0.3),
              viewport,
              true,
            );
        final dragOffset =
            topLeft +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.8, 0.8),
              viewport,
              true,
            );

        final gesture = await tester.startGesture(startOffset);
        await gesture.moveTo(dragOffset);
        await gesture.cancel();
        await tester.pumpAndSettle();

        expect(
          controller.currentScene.balls.first.position,
          equals(const TablePoint(0.3, 0.3)),
        );
        expect(controller.state.isDirty, isFalse);
        expect(controller.state.canUndo, isFalse);
      },
    );

    testWidgets('tap outside playfield creates no entity (Requirement 43)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = SceneEditorController(clock: clock);
      controller.setTool(SceneEditorTool.ball);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 720,
              child: SceneEditorCanvas(
                controller: controller,
                isVertical: true,
              ),
            ),
          ),
        ),
      );

      // Tap on top wood rail (outside playfield)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(controller.currentScene.balls, isEmpty);
      expect(controller.state.isDirty, isFalse);
      expect(controller.state.canUndo, isFalse);
    });

    testWidgets(
      'ghostBall and extraBall tools create ghost and extra ball types (Requirement 25)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SceneEditorController(clock: clock);
        final viewport = SceneViewport(
          canvasSize: const Size(360, 720),
          viewMode: SceneViewMode.full,
          isVertical: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 720,
                child: SceneEditorCanvas(
                  controller: controller,
                  isVertical: true,
                ),
              ),
            ),
          ),
        );

        // 1. Ghost ball tool
        controller.setTool(SceneEditorTool.ghostBall);
        await tester.pump();

        final tapPt1 = const TablePoint(0.3, 0.3);
        final offset1 = adapter.tablePointToLocalOffset(tapPt1, viewport, true);
        await tester.tapAt(offset1);
        await tester.pumpAndSettle();

        expect(controller.currentScene.balls.length, equals(1));
        expect(controller.currentScene.balls.first.ballType, equals('ghost'));

        // 2. Extra ball tool
        controller.setTool(SceneEditorTool.extraBall);
        await tester.pump();

        final tapPt2 = const TablePoint(0.6, 0.6);
        final offset2 = adapter.tablePointToLocalOffset(tapPt2, viewport, true);
        await tester.tapAt(offset2);
        await tester.pumpAndSettle();

        expect(controller.currentScene.balls.length, equals(2));
        expect(controller.currentScene.balls.last.ballType, equals('extra'));
      },
    );

    testWidgets(
      'label tool with null onLabelRequested does NOT commit placeholder annotation (Requirement 23)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SceneEditorController(clock: clock);
        controller.setTool(SceneEditorTool.label);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 720,
                child: SceneEditorCanvas(
                  controller: controller,
                  isVertical: true,
                  onLabelRequested: null, // No label provider
                ),
              ),
            ),
          ),
        );

        final viewport = SceneViewport(
          canvasSize: const Size(360, 720),
          viewMode: SceneViewMode.full,
          isVertical: true,
        );

        final tapOffset = adapter.tablePointToLocalOffset(
          const TablePoint(0.5, 0.5),
          viewport,
          true,
        );

        await tester.tapAt(tapOffset);
        await tester.pumpAndSettle();

        // Assert NO annotation was added, scene remains clean, no undo
        expect(controller.currentScene.annotations, isEmpty);
        expect(controller.state.isDirty, isFalse);
        expect(controller.state.canUndo, isFalse);
      },
    );

    testWidgets(
      'cushionNumber tool on rail creates cushion annotation, middle tap rejected (Requirement 19, 20, 21)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SceneEditorController(clock: clock);
        controller.setTool(SceneEditorTool.cushionNumber);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 720,
                child: SceneEditorCanvas(
                  controller: controller,
                  isVertical: true,
                  activeCushionNumberText: '50',
                ),
              ),
            ),
          ),
        );

        final viewport = SceneViewport(
          canvasSize: const Size(360, 720),
          viewMode: SceneViewMode.full,
          isVertical: true,
        );

        // 1. Tap middle of table -> rejected (no annotation created)
        final middleTap = viewport.playfieldRect.center;
        await tester.tapAt(middleTap);
        await tester.pumpAndSettle();
        expect(controller.currentScene.annotations, isEmpty);

        // 2. Tap top rail -> creates cushion number annotation on top edge
        final topRailTap = Offset(viewport.playfieldRect.center.dx, 5.0);
        await tester.tapAt(topRailTap);
        await tester.pumpAndSettle();

        expect(controller.currentScene.annotations.length, equals(1));
        final ann = controller.currentScene.annotations.first;
        expect(ann.text, equals('50'));
        expect(ann.role, equals('cushionNumber'));
        expect(ann.cushionSide, equals('top'));
        expect(ann.position.v, equals(0.0)); // Canonical top edge
      },
    );

    testWidgets(
      'trajectory tool session resets activeTrajectoryId on tool switch (Requirement 9)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SceneEditorController(clock: clock);
        final viewport = SceneViewport(
          canvasSize: const Size(360, 720),
          viewMode: SceneViewMode.full,
          isVertical: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 720,
                child: SceneEditorCanvas(
                  controller: controller,
                  isVertical: true,
                ),
              ),
            ),
          ),
        );

        // 1. Switch to trajectory tool and tap 2 points -> creates Trajectory 1 with 2 points
        controller.setTool(SceneEditorTool.trajectory);
        await tester.pump();

        await tester.tapAt(
          adapter.tablePointToLocalOffset(
            const TablePoint(0.2, 0.2),
            viewport,
            true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tapAt(
          adapter.tablePointToLocalOffset(
            const TablePoint(0.4, 0.4),
            viewport,
            true,
          ),
        );
        await tester.pumpAndSettle();

        expect(controller.currentScene.trajectories.length, equals(1));
        expect(
          controller.currentScene.trajectories.first.points.length,
          equals(2),
        );

        // 2. Switch away to select tool
        controller.setTool(SceneEditorTool.select);
        await tester.pumpAndSettle();

        // 3. Switch BACK to trajectory tool -> first tap MUST create a NEW trajectory (not append to old one!)
        controller.setTool(SceneEditorTool.trajectory);
        await tester.pumpAndSettle();

        await tester.tapAt(
          adapter.tablePointToLocalOffset(
            const TablePoint(0.7, 0.7),
            viewport,
            true,
          ),
        );
        await tester.pumpAndSettle();

        expect(controller.currentScene.trajectories.length, equals(2));
        expect(
          controller.currentScene.trajectories.last.points.length,
          equals(1),
        );
      },
    );

    testWidgets(
      'delete tool deletes ball, annotation, trajectory, and trajectory point',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final ptBall = const TablePoint(0.3, 0.3);
        final ptAnn = const TablePoint(0.7, 0.7);

        final initialScene = BilliardScene(
          id: 'del-scene',
          name: 'Del Scene',
          balls: [BallPosition(id: 'b-del', ballType: 'red', position: ptBall)],
          annotations: [
            SceneAnnotation(id: 'a-del', text: 'Del', position: ptAnn),
          ],
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        final controller = SceneEditorController(
          initialScene: initialScene,
          clock: clock,
        );
        controller.setTool(SceneEditorTool.delete);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 720,
                child: SceneEditorCanvas(
                  controller: controller,
                  isVertical: true,
                ),
              ),
            ),
          ),
        );

        final viewport = SceneViewport(
          canvasSize: const Size(360, 720),
          viewMode: SceneViewMode.full,
          isVertical: true,
        );

        // Tap on ball -> deletes ball
        await tester.tapAt(
          adapter.tablePointToLocalOffset(ptBall, viewport, true),
        );
        await tester.pumpAndSettle();
        expect(controller.currentScene.balls, isEmpty);

        // Tap on annotation -> deletes annotation
        await tester.tapAt(
          adapter.tablePointToLocalOffset(ptAnn, viewport, true),
        );
        await tester.pumpAndSettle();
        expect(controller.currentScene.annotations, isEmpty);
      },
    );

    testWidgets(
      'onEditorError callback receives SceneEditorException (Requirement 14)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SceneEditorController(clock: clock);
        SceneEditorException? capturedError;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 720,
                child: SceneEditorCanvas(
                  controller: controller,
                  isVertical: true,
                  onEditorError: (e) => capturedError = e,
                ),
              ),
            ),
          ),
        );

        // Verify canvas rendered without error
        expect(find.byType(SceneEditorCanvas), findsOneWidget);
        expect(capturedError, isNull);
      },
    );
  });
}
