// Widget Unit Tests for SceneEditorToolbar (Phase 4B)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/application/scene_editor/scene_editor_controller.dart';
import 'package:libre2026/application/scene_editor/scene_editor_tool.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';
import 'package:libre2026/presentation/scene_editor/scene_editor_canvas.dart';
import 'package:libre2026/presentation/scene_editor/scene_editor_toolbar.dart';

void main() {
  group('SceneEditorToolbar Widget Tests (Phase 4B)', () {
    late DateTime fixedTime;
    late DateTime Function() clock;

    setUp(() {
      fixedTime = DateTime.utc(2026, 9, 23, 10, 0, 0);
      clock = () => fixedTime;
    });

    testWidgets(
      'Undo / Redo UI toolbar flow and tool selection (Requirements 11 & 12)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SceneEditorController(clock: clock);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SceneEditorToolbar(controller: controller),
                  Expanded(
                    child: SceneEditorCanvas(
                      controller: controller,
                      isVertical: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final undoFinder = find.byKey(const Key('toolbar_undo_button'));
        final redoFinder = find.byKey(const Key('toolbar_redo_button'));

        expect(undoFinder, findsOneWidget);
        expect(redoFinder, findsOneWidget);

        // 1. Initial state: Undo & Redo disabled
        IconButton undoButton = tester.widget(undoFinder);
        IconButton redoButton = tester.widget(redoFinder);

        expect(undoButton.onPressed, isNull);
        expect(redoButton.onPressed, isNull);

        // 2. Perform edit via controller -> Undo becomes enabled
        controller.addBall(
          ballType: 'white',
          position: const TablePoint(0.5, 0.5),
        );
        await tester.pumpAndSettle();

        undoButton = tester.widget(undoFinder);
        redoButton = tester.widget(redoFinder);

        expect(undoButton.onPressed, isNotNull);
        expect(redoButton.onPressed, isNull);
        expect(controller.currentScene.balls.length, equals(1));

        // 3. Tap Undo button in toolbar -> scene visually restores, Redo enabled
        await tester.tap(undoFinder);
        await tester.pumpAndSettle();

        undoButton = tester.widget(undoFinder);
        redoButton = tester.widget(redoFinder);

        expect(undoButton.onPressed, isNull);
        expect(redoButton.onPressed, isNotNull);
        expect(controller.currentScene.balls, isEmpty);

        // 4. Tap Redo button in toolbar -> scene visually reapplies, Undo enabled
        await tester.tap(redoFinder);
        await tester.pumpAndSettle();

        undoButton = tester.widget(undoFinder);
        redoButton = tester.widget(redoFinder);

        expect(undoButton.onPressed, isNotNull);
        expect(redoButton.onPressed, isNull);
        expect(controller.currentScene.balls.length, equals(1));

        // 5. Tool selection buttons in toolbar update controller active tool
        final ballToolFinder = find.byKey(const Key('tool_ball_button'));
        expect(ballToolFinder, findsOneWidget);

        await tester.tap(ballToolFinder);
        await tester.pumpAndSettle();

        expect(controller.state.activeTool, equals(SceneEditorTool.ball));
      },
    );
  });
}
