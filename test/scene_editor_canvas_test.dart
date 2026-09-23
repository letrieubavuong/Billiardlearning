// Widget Unit Tests for SceneEditorCanvas (Phase 4B)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/application/scene_editor/scene_editor_controller.dart';
import 'package:libre2026/application/scene_editor/scene_editor_exception.dart';
import 'package:libre2026/application/scene_editor/scene_editor_selection.dart';
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

      final topLeft = tester.getTopLeft(find.byType(SceneEditorCanvas));
      // Tap on top wood rail (outside playfield)
      await tester.tapAt(topLeft + const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(controller.currentScene.balls, isEmpty);
      expect(controller.state.isDirty, isFalse);
      expect(controller.state.canUndo, isFalse);
    });

    testWidgets(
      'drag outside visible crop clamps object to visible crop edge (Requirement 2, 3, 5)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. Half view mode: visible v in [0, 0.5]
        final initialScene = BilliardScene(
          id: 'half-drag-scene',
          name: 'Half Drag',
          balls: const [
            BallPosition(
              id: 'b-half',
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
                height: 360,
                child: SceneEditorCanvas(
                  controller: controller,
                  viewMode: SceneViewMode.half,
                  isVertical: true,
                ),
              ),
            ),
          ),
        );

        final halfViewport = SceneViewport(
          canvasSize: const Size(360, 360),
          viewMode: SceneViewMode.half,
          isVertical: true,
        );

        final topLeft1 = tester.getTopLeft(find.byType(SceneEditorCanvas));
        final startOffset =
            topLeft1 +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.2, 0.2),
              halfViewport,
              true,
            );

        // Drag far below visible bottom crop edge (corresponding to v = 0.8 on full table)
        final dragBelowOffset = topLeft1 + Offset(startOffset.dx, 500.0);

        final gesture = await tester.startGesture(startOffset);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveTo(startOffset + const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveTo(dragBelowOffset);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();

        // Ball position MUST be clamped to visible bottom crop edge (v = 0.56 for half mode without bottom rail)
        final movedBall = controller.currentScene.balls.first;
        expect(movedBall.position.v, closeTo(0.56, 0.02));

        // 2. HalfWidth view mode: visible u in [0, 0.5]
        final hwScene = BilliardScene(
          id: 'hw-drag-scene',
          name: 'HW Drag',
          balls: const [
            BallPosition(
              id: 'b-hw',
              ballType: 'red',
              position: TablePoint(0.2, 0.2),
            ),
          ],
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        final hwController = SceneEditorController(
          initialScene: hwScene,
          clock: clock,
        );
        hwController.setTool(SceneEditorTool.move);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 720,
                child: SceneEditorCanvas(
                  controller: hwController,
                  viewMode: SceneViewMode.halfWidth,
                  isVertical: true,
                ),
              ),
            ),
          ),
        );

        final hwViewport = SceneViewport(
          canvasSize: const Size(200, 720),
          viewMode: SceneViewMode.halfWidth,
          isVertical: true,
        );

        final topLeft2 = tester.getTopLeft(find.byType(SceneEditorCanvas));
        final hwStart =
            topLeft2 +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.2, 0.2),
              hwViewport,
              true,
            );
        final hwDragRight =
            topLeft2 + Offset(400.0, hwStart.dy); // Drag far right

        final hwGesture = await tester.startGesture(hwStart);
        await tester.pump(const Duration(milliseconds: 50));
        await hwGesture.moveTo(hwStart + const Offset(20, 0));
        await tester.pump(const Duration(milliseconds: 50));
        await hwGesture.moveTo(hwDragRight);
        await tester.pump(const Duration(milliseconds: 50));
        await hwGesture.up();
        await tester.pumpAndSettle();

        // Ball position MUST be clamped to visible right crop edge (u = 0.5)
        final movedHwBall = hwController.currentScene.balls.first;
        expect(movedHwBall.position.u, closeTo(0.5, 0.02));
      },
    );

    testWidgets(
      'cushionNumber annotations can be selected and deleted on top, bottom, and right rails (Requirements 9 & 10)',
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
                  activeCushionNumberText: '20',
                ),
              ),
            ),
          ),
        );

        final topLeft = tester.getTopLeft(find.byType(SceneEditorCanvas));

        // 1. Create cushion numbers on top, bottom, and right rails
        controller.setTool(SceneEditorTool.cushionNumber);
        await tester.pump();

        final topRailOffset =
            topLeft +
            Offset(viewport.playfieldRect.center.dx, viewport.totalRail * 0.5);
        await tester.tapAt(topRailOffset);
        await tester.pumpAndSettle();
        final topAnnId = controller.currentScene.annotations.last.id;

        final bottomRailOffset =
            topLeft +
            Offset(
              viewport.playfieldRect.center.dx,
              viewport.canvasSize.height - viewport.totalRail * 0.5,
            );
        await tester.tapAt(bottomRailOffset);
        await tester.pumpAndSettle();
        final bottomAnnId = controller.currentScene.annotations.last.id;

        final rightRailOffset =
            topLeft +
            Offset(
              viewport.canvasSize.width - viewport.totalRail * 0.5,
              viewport.playfieldRect.center.dy,
            );
        await tester.tapAt(rightRailOffset);
        await tester.pumpAndSettle();
        final rightAnnId = controller.currentScene.annotations.last.id;

        expect(controller.currentScene.annotations.length, equals(3));

        // 2. Select cushion number annotation on top rail with Select tool (Requirement 10)
        controller.setTool(SceneEditorTool.select);
        await tester.pump();

        await tester.tapAt(topRailOffset);
        await tester.pumpAndSettle();

        expect(
          controller.state.selection,
          equals(SceneEditorSelection.annotation(topAnnId)),
        );

        // 3. Delete cushion number annotations on rails with Delete tool (Requirement 9)
        controller.setTool(SceneEditorTool.delete);
        await tester.pump();

        // Delete top rail cushion number
        await tester.tapAt(topRailOffset);
        await tester.pumpAndSettle();
        expect(
          controller.currentScene.annotations.any((a) => a.id == topAnnId),
          isFalse,
        );

        // Delete bottom rail cushion number
        await tester.tapAt(bottomRailOffset);
        await tester.pumpAndSettle();
        expect(
          controller.currentScene.annotations.any((a) => a.id == bottomAnnId),
          isFalse,
        );

        // Delete right rail cushion number
        await tester.tapAt(rightRailOffset);
        await tester.pumpAndSettle();
        expect(
          controller.currentScene.annotations.any((a) => a.id == rightAnnId),
          isFalse,
        );

        expect(controller.currentScene.annotations, isEmpty);
      },
    );

    testWidgets(
      'error propagation rethrows exception when onEditorError is null and passes exception when handler provided (Requirements 11, 12, 13)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final initialScene = BilliardScene(
          id: 'race-scene',
          name: 'Race Scene',
          balls: const [
            BallPosition(
              id: 'b-race',
              ballType: 'red',
              position: TablePoint(0.3, 0.3),
            ),
          ],
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        final viewport = SceneViewport(
          canvasSize: const Size(360, 720),
          viewMode: SceneViewMode.full,
          isVertical: true,
        );

        // 1. With handler provided (Requirement 12)
        final controllerWithHandler = SceneEditorController(
          initialScene: initialScene,
          clock: clock,
        );
        controllerWithHandler.setTool(SceneEditorTool.move);
        SceneEditorException? capturedError;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 720,
                child: SceneEditorCanvas(
                  controller: controllerWithHandler,
                  isVertical: true,
                  onEditorError: (e) => capturedError = e,
                ),
              ),
            ),
          ),
        );

        final topLeft1 = tester.getTopLeft(find.byType(SceneEditorCanvas));
        final startOffset1 =
            topLeft1 +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.3, 0.3),
              viewport,
              true,
            );
        final dragOffset1 =
            topLeft1 +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.7, 0.7),
              viewport,
              true,
            );

        // Start drag on ball b-race
        final gesture1 = await tester.startGesture(startOffset1);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture1.moveTo(startOffset1 + const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture1.moveTo(dragOffset1);
        await tester.pump(const Duration(milliseconds: 50));

        // Delete ball b-race mid-drag via controller
        controllerWithHandler.deleteBall('b-race');

        // Finish drag -> moveBall('b-race') throws SceneEditorTargetNotFoundException
        await gesture1.up();
        await tester.pumpAndSettle();

        expect(capturedError, isA<SceneEditorTargetNotFoundException>());

        // 2. Without handler (onEditorError == null, Requirement 13) -> exception rethrown
        final controllerNoHandler = SceneEditorController(
          initialScene: initialScene,
          clock: clock,
        );
        controllerNoHandler.setTool(SceneEditorTool.move);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 720,
                child: SceneEditorCanvas(
                  controller: controllerNoHandler,
                  isVertical: true,
                  onEditorError: null,
                ),
              ),
            ),
          ),
        );

        final topLeft2 = tester.getTopLeft(find.byType(SceneEditorCanvas));
        final startOffset2 =
            topLeft2 +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.3, 0.3),
              viewport,
              true,
            );
        final dragOffset2 =
            topLeft2 +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.7, 0.7),
              viewport,
              true,
            );

        final gesture2 = await tester.startGesture(startOffset2);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture2.moveTo(startOffset2 + const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture2.moveTo(dragOffset2);
        await tester.pump(const Duration(milliseconds: 50));

        // Delete ball b-race mid-drag via controller
        controllerNoHandler.deleteBall('b-race');

        // Finish drag -> moveBall('b-race') rethrows SceneEditorTargetNotFoundException
        await gesture2.up();
        await tester.pumpAndSettle();

        final dynamic exception = tester.takeException();
        expect(exception, isA<SceneEditorTargetNotFoundException>());
      },
    );

    testWidgets(
      'move annotation and move trajectory point widget flows (Requirement 14)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final initialScene = BilliardScene(
          id: 'move-scene',
          name: 'Move Scene',
          annotations: const [
            SceneAnnotation(
              id: 'ann-m',
              text: 'Label',
              position: TablePoint(0.2, 0.2),
            ),
          ],
          trajectories: const [
            TrajectoryLine(
              id: 'traj-m',
              points: [TablePoint(0.4, 0.4), TablePoint(0.6, 0.6)],
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
        controller.select(const SceneEditorSelection.annotation('ann-m'));

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

        // 1. Move annotation from (0.2, 0.2) to (0.5, 0.5)
        final annStart =
            topLeft +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.2, 0.2),
              viewport,
              true,
            );
        final annTarget =
            topLeft +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.5, 0.5),
              viewport,
              true,
            );

        await tester.dragFrom(annStart, annTarget - annStart);
        await tester.pumpAndSettle();

        final movedAnn = controller.currentScene.annotations.first;
        expect(movedAnn.position.u, closeTo(0.5, 0.02));
        expect(controller.state.canUndo, isTrue);

        controller.undo();
        expect(
          controller.currentScene.annotations.first.position,
          equals(const TablePoint(0.2, 0.2)),
        );

        // 2. Move trajectory point from (0.4, 0.4) to (0.8, 0.8)
        final tpStart =
            topLeft +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.4, 0.4),
              viewport,
              true,
            );
        final tpTarget =
            topLeft +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.8, 0.8),
              viewport,
              true,
            );

        final g2 = await tester.startGesture(tpStart);
        await tester.pump(const Duration(milliseconds: 50));
        await g2.moveTo(tpStart + const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 50));
        await g2.moveTo(tpTarget);
        await tester.pump(const Duration(milliseconds: 50));
        await g2.up();
        await tester.pumpAndSettle();

        final movedTp = controller.currentScene.trajectories.first.points.first;
        expect(movedTp.u, closeTo(0.8, 0.02));
        expect(controller.state.canUndo, isTrue);

        controller.undo();
        expect(
          controller.currentScene.trajectories.first.points.first,
          equals(const TablePoint(0.4, 0.4)),
        );
      },
    );

    testWidgets(
      'select tool taps entity and clears selection on empty area (Requirement 15)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final initialScene = BilliardScene(
          id: 'sel-scene',
          name: 'Sel Scene',
          balls: const [
            BallPosition(
              id: 'b-sel',
              ballType: 'red',
              position: TablePoint(0.4, 0.4),
            ),
          ],
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        final controller = SceneEditorController(
          initialScene: initialScene,
          clock: clock,
        );
        controller.setTool(SceneEditorTool.select);

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

        // Tap ball -> selection becomes ball ID
        final ballOffset =
            topLeft +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.4, 0.4),
              viewport,
              true,
            );
        await tester.tapAt(ballOffset);
        await tester.pumpAndSettle();

        expect(
          controller.state.selection,
          equals(const SceneEditorSelection.ball('b-sel')),
        );

        // Tap empty area -> selection becomes none
        final emptyOffset =
            topLeft +
            adapter.tablePointToLocalOffset(
              const TablePoint(0.1, 0.1),
              viewport,
              true,
            );
        await tester.tapAt(emptyOffset);
        await tester.pumpAndSettle();

        expect(
          controller.state.selection,
          equals(const SceneEditorSelection.none()),
        );
      },
    );

    testWidgets(
      'regular ball tool creates red ball on visible playfield (Requirement 16)',
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
                  activeBallType: 'red',
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
        expect(controller.currentScene.balls.first.ballType, equals('red'));
      },
    );

    testWidgets(
      'ghostBall tool creates ghost ball on visible playfield (Requirement 16)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SceneEditorController(clock: clock);
        controller.setTool(SceneEditorTool.ghostBall);

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
        expect(controller.currentScene.balls.first.ballType, equals('ghost'));
        expect(controller.state.isDirty, isTrue);
        expect(controller.state.canUndo, isTrue);
      },
    );

    testWidgets(
      'extraBall tool creates extra ball on visible playfield and is not treated as ghost',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SceneEditorController(clock: clock);
        controller.setTool(SceneEditorTool.extraBall);

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
        final addedBall = controller.currentScene.balls.first;
        expect(addedBall.ballType, equals('extra'));
        expect(addedBall.ballType, isNot(equals('ghost')));
        expect(controller.state.isDirty, isTrue);
        expect(controller.state.canUndo, isTrue);
      },
    );

    testWidgets(
      'trajectory tool creates new trajectory line on tap A and appends point on tap B',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SceneEditorController(clock: clock);
        controller.setTool(SceneEditorTool.trajectory);

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

        // Tap A -> creates trajectory 1 with one point
        final ptA = const TablePoint(0.3, 0.3);
        await tester.tapAt(
          topLeft + adapter.tablePointToLocalOffset(ptA, viewport, true),
        );
        await tester.pumpAndSettle();

        expect(controller.currentScene.trajectories.length, equals(1));
        expect(
          controller.currentScene.trajectories.first.points.length,
          equals(1),
        );

        // Tap B -> appends second point to trajectory 1
        final ptB = const TablePoint(0.6, 0.6);
        await tester.tapAt(
          topLeft + adapter.tablePointToLocalOffset(ptB, viewport, true),
        );
        await tester.pumpAndSettle();

        expect(controller.currentScene.trajectories.length, equals(1));
        expect(
          controller.currentScene.trajectories.first.points.length,
          equals(2),
        );
      },
    );

    testWidgets(
      'switching away from trajectory tool resets activeTrajectoryId session',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SceneEditorController(clock: clock);
        controller.setTool(SceneEditorTool.trajectory);

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

        // Tap A and B -> Trajectory 1 has 2 points
        await tester.tapAt(
          topLeft +
              adapter.tablePointToLocalOffset(
                const TablePoint(0.2, 0.2),
                viewport,
                true,
              ),
        );
        await tester.pumpAndSettle();
        await tester.tapAt(
          topLeft +
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

        // Switch to select, then back to trajectory
        controller.setTool(SceneEditorTool.select);
        await tester.pumpAndSettle();
        controller.setTool(SceneEditorTool.trajectory);
        await tester.pumpAndSettle();

        // Tap C -> creates Trajectory 2 with 1 point
        await tester.tapAt(
          topLeft +
              adapter.tablePointToLocalOffset(
                const TablePoint(0.7, 0.7),
                viewport,
                true,
              ),
        );
        await tester.pumpAndSettle();

        expect(controller.currentScene.trajectories.length, equals(2));
        expect(
          controller.currentScene.trajectories[0].points.length,
          equals(2),
        );
        expect(
          controller.currentScene.trajectories[1].points.length,
          equals(1),
        );
      },
    );

    testWidgets(
      'label tool positive flow invokes onLabelRequested and repaints when annotation added (Requirement 17)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SceneEditorController(clock: clock);
        controller.setTool(SceneEditorTool.label);
        TablePoint? requestedPosition;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 720,
                child: SceneEditorCanvas(
                  controller: controller,
                  isVertical: true,
                  onLabelRequested: (pos) {
                    requestedPosition = pos;
                    // Emulate UI owner adding annotation through controller
                    controller.addAnnotation(text: 'User Text', position: pos);
                  },
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
              const TablePoint(0.4, 0.4),
              viewport,
              true,
            );
        await tester.tapAt(tapOffset);
        await tester.pumpAndSettle();

        expect(requestedPosition, isNotNull);
        expect(requestedPosition!.u, closeTo(0.4, 0.02));
        expect(controller.currentScene.annotations.length, equals(1));
        expect(
          controller.currentScene.annotations.first.text,
          equals('User Text'),
        );
      },
    );

    testWidgets(
      'delete tool performs separate explicit UI deletions for ball, annotation, trajectory point, and trajectory line segment (Requirement 18)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final ptBall = const TablePoint(0.2, 0.2);
        final ptAnn = const TablePoint(0.8, 0.8);
        final ptTp0 = const TablePoint(0.3, 0.3);
        final ptTp1 = const TablePoint(0.7, 0.7);
        final ptLineMid = const TablePoint(0.5, 0.5);

        final initialScene = BilliardScene(
          id: 'del-all-scene',
          name: 'Del All Scene',
          balls: [BallPosition(id: 'b-del', ballType: 'red', position: ptBall)],
          annotations: [
            SceneAnnotation(id: 'a-del', text: 'Del', position: ptAnn),
          ],
          trajectories: [
            TrajectoryLine(id: 't-del', points: [ptTp0, ptTp1]),
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

        final topLeft = tester.getTopLeft(find.byType(SceneEditorCanvas));

        // 1. Explicit UI assertion for deleting ball
        await tester.tapAt(
          topLeft + adapter.tablePointToLocalOffset(ptBall, viewport, true),
        );
        await tester.pumpAndSettle();
        expect(controller.currentScene.balls, isEmpty);

        // 2. Explicit UI assertion for deleting annotation
        await tester.tapAt(
          topLeft + adapter.tablePointToLocalOffset(ptAnn, viewport, true),
        );
        await tester.pumpAndSettle();
        expect(controller.currentScene.annotations, isEmpty);

        // 3. Explicit UI assertion for deleting trajectory point (tap control point ptTp0)
        await tester.tapAt(
          topLeft + adapter.tablePointToLocalOffset(ptTp0, viewport, true),
        );
        await tester.pumpAndSettle();
        expect(
          controller.currentScene.trajectories.first.points.length,
          equals(1),
        );

        // 4. Explicit UI assertion for deleting trajectory line segment through SceneEditorCanvas hit-test
        // Add ptTp0 back so trajectory has distinct points (0.3, 0.3) and (0.7, 0.7)
        controller.addTrajectoryPoint('t-del', ptTp0);
        expect(
          controller.currentScene.trajectories.first.points.length,
          equals(2),
        );

        // Tap line segment midpoint away from control points
        await tester.tapAt(
          topLeft + adapter.tablePointToLocalOffset(ptLineMid, viewport, true),
        );
        await tester.pumpAndSettle();

        expect(controller.currentScene.trajectories, isEmpty);
      },
    );
  });
}
