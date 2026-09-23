// Widget Unit Tests for SceneEditorCanvas (Phase 4B)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/application/scene_editor/scene_editor_controller.dart';
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
      'tap-to-add ball tool creates ball at tapped location (Requirement 23)',
      (WidgetTester tester) async {
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
                  activeBallType: 'yellow',
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

        final tapOffset =
            topLeft +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.5, 0.5),
              viewport,
              true,
            );

        await tester.tapAt(tapOffset);
        await tester.pumpAndSettle();

        expect(controller.currentScene.balls.length, equals(1));
        expect(controller.currentScene.balls.first.ballType, equals('yellow'));
        expect(
          controller.currentScene.balls.first.position.u,
          closeTo(0.5, 0.05),
        );
        expect(controller.state.isDirty, isTrue);
        expect(controller.state.canUndo, isTrue);
      },
    );
  });
}
