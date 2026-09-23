// Smoke tests for SceneRenderer widget and LegacyRenderAdapter in Phase 3

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';
import 'package:libre2026/rendering/scene/scene_render_model.dart';
import 'package:libre2026/rendering/scene/scene_renderer.dart';
import 'package:libre2026/rendering/scene/legacy/legacy_render_adapter.dart';
import 'package:libre2026/rendering/scene/scene_viewport.dart';
import 'package:libre2026/screens/home_page.dart';
import 'package:libre2026/screens/phase3_visual_qa_page.dart';
import 'package:libre2026/widgets/billiard_diagram.dart';

void main() {
  group('SceneRenderer Smoke Tests', () {
    testWidgets('SceneRenderer renders SceneRenderModel without exception', (
      tester,
    ) async {
      const model = SceneRenderModel(
        balls: [
          BallRenderItem(position: TablePoint(0.25, 0.75), color: Colors.white),
          BallRenderItem(position: TablePoint(0.5, 0.5), color: Colors.yellow),
          BallRenderItem(position: TablePoint(0.75, 0.25), color: Colors.red),
        ],
        trajectories: [
          TrajectoryRenderItem(
            points: [
              TablePoint(0.25, 0.75),
              TablePoint(0.5, 0.5),
              TablePoint(0.75, 0.25),
            ],
            color: Colors.white70,
            isDashed: true,
          ),
        ],
        annotations: [
          AnnotationRenderItem(
            position: TablePoint(0.5, 0.5),
            text: 'Cue Ball',
            color: Colors.cyanAccent,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: SceneRenderer(model: model),
            ),
          ),
        ),
      );

      expect(find.byType(SceneRenderer), findsOneWidget);
    });

    testWidgets(
      'LegacyRenderAdapter converts BilliardScene to SceneRenderModel cleanly',
      (tester) async {
        final now = DateTime.now();
        final scene = BilliardScene(
          id: 'scene-1',
          name: 'Test Scene',
          balls: const [
            BallPosition(
              id: 'ball-1',
              ballType: 'white',
              position: TablePoint(0.25, 0.75),
            ),
            BallPosition(
              id: 'ball-2',
              ballType: 'yellow',
              position: TablePoint(0.5, 0.5),
            ),
          ],
          trajectories: const [
            TrajectoryLine(
              id: 'traj-1',
              colorHex: '#FFFFFFFF',
              points: [TablePoint(0.25, 0.75), TablePoint(0.5, 0.5)],
            ),
          ],
          annotations: const [
            SceneAnnotation(
              id: 'ann-1',
              text: 'Annotation Label',
              position: TablePoint(0.5, 0.5),
              colorHex: '#FFFF0000',
            ),
          ],
          presentationConfig: ScenePresentationConfig(
            legacyViewTypeIndex: 0,
            legacySystemIndex: 0,
          ),
          createdAt: now,
          updatedAt: now,
        );

        final renderModel = LegacyRenderAdapter.sceneToRenderModel(
          scene: scene,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: SceneRenderer(model: renderModel),
              ),
            ),
          ),
        );

        expect(find.byType(SceneRenderer), findsOneWidget);
        expect(renderModel.balls.length, equals(2));
        expect(renderModel.trajectories.length, equals(1));
        expect(renderModel.annotations.length, equals(1));
      },
    );

    test(
      'Domain ghost ball converts to isGhost=true and rotation in radians',
      () {
        final now = DateTime.now();
        final scene = BilliardScene(
          id: 'scene-ghost',
          name: 'Ghost Test Scene',
          balls: const [
            BallPosition(
              id: 'ghost-1',
              ballType: 'ghost',
              position: TablePoint(0.5, 0.5),
              rotation: 90.0,
              legacyType: 1,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );

        final renderModel = LegacyRenderAdapter.sceneToRenderModel(
          scene: scene,
        );
        final ballItem = renderModel.balls.single;

        expect(ballItem.isGhost, isTrue);
        expect(ballItem.ballTypeIndex, equals(1));
        expect(ballItem.rotationInRadians, closeTo(math.pi / 2, 1e-6));
        expect(ballItem.opacity, closeTo(0.5, 1e-6));
      },
    );

    test(
      'Domain extra labelled ball converts to numbered ball (ballTypeIndex=2)',
      () {
        final now = DateTime.now();
        final scene = BilliardScene(
          id: 'scene-extra',
          name: 'Extra Ball Scene',
          balls: const [
            BallPosition(
              id: 'extra-1',
              ballType: 'extra',
              position: TablePoint(0.5, 0.5),
              label: '7',
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );

        final renderModel = LegacyRenderAdapter.sceneToRenderModel(
          scene: scene,
        );
        final ballItem = renderModel.balls.single;

        expect(ballItem.ballTypeIndex, equals(2));
        expect(ballItem.text, equals('7'));
      },
    );

    test(
      'Domain extra ball with legacyType=1 converts to isGhost=false and ballTypeIndex=1',
      () {
        final now = DateTime.now();
        final scene = BilliardScene(
          id: 'scene-extra-half',
          name: 'Half Extra Scene',
          balls: const [
            BallPosition(
              id: 'half-extra',
              ballType: 'extra',
              position: TablePoint(0.5, 0.5),
              legacyType: 1,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );

        final renderModel = LegacyRenderAdapter.sceneToRenderModel(
          scene: scene,
        );
        final ballItem = renderModel.balls.single;

        expect(ballItem.isGhost, isFalse);
        expect(ballItem.ballTypeIndex, equals(1));
        expect(ballItem.opacity, equals(1.0));
      },
    );

    testWidgets('BilliardDiagram delegates to new renderer without exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: BilliardDiagram(
                balls: [
                  Ball.at(1, 1, Colors.white),
                  Ball.at(2, 2, Colors.yellow),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BilliardDiagram), findsOneWidget);
    });

    testWidgets('Phase3VisualQaPage renders without exception', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Phase3VisualQaPage()));

      expect(find.byType(Phase3VisualQaPage), findsOneWidget);
    });

    testWidgets(
      'Phase3VisualQaPage human checklist defaults to verified count = 0 / 19',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: Phase3VisualQaPage()));

        expect(find.text('Verified: 0 / 19'), findsOneWidget);
        expect(find.text('HUMAN VERIFICATION: PENDING'), findsOneWidget);
      },
    );

    testWidgets(
      'Phase3VisualQaPage allows selecting Xô hai băng and Ba băng chạm systems',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: Phase3VisualQaPage()));

        expect(find.text('System: Diamond'), findsOneWidget);

        final xohaibangFinder = find.widgetWithText(ChoiceChip, 'Xô hai băng');
        expect(xohaibangFinder, findsOneWidget);
        await tester.ensureVisible(xohaibangFinder);
        await tester.tap(xohaibangFinder);
        await tester.pump();

        expect(find.text('System: Xô hai băng'), findsOneWidget);
        expect(tester.takeException(), isNull);

        final babangchaFinder = find.widgetWithText(ChoiceChip, 'Ba băng chạm');
        expect(babangchaFinder, findsOneWidget);
        await tester.ensureVisible(babangchaFinder);
        await tester.tap(babangchaFinder);
        await tester.pump();

        expect(find.text('System: Ba băng chạm'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Debug entry point in home page opens Phase3VisualQaPage', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MyHomePage()));

      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.dragFrom(const Offset(150, 400), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 300));

      final finder = find.text('Phase 3 Visual QA');
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Phase3VisualQaPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Phase3QaPreview preserves logical aspect ratio across all 8 view modes and phone constraints',
      (tester) async {
        // Set phone viewport (390 x 844)
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final modes = SceneViewMode.values;
        const testOrientations = [true, false]; // Vertical, Horizontal

        for (final isVertical in testOrientations) {
          for (final mode in modes) {
            final logicalSize = phase3QaCanvasSize(
              mode,
              isVertical: isVertical,
              targetWidth: isVertical ? 260.0 : 600.0,
            );

            const model = SceneRenderModel(
              balls: [
                BallRenderItem(
                  position: TablePoint(0.5, 0.5),
                  color: Colors.white,
                ),
              ],
            );

            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: SizedBox(
                    width: 360,
                    height: 600,
                    child: Phase3QaPreview(
                      model: model,
                      logicalSize: logicalSize,
                    ),
                  ),
                ),
              ),
            );

            expect(tester.takeException(), isNull);

            final previewFinder = find.descendant(
              of: find.byType(Phase3QaPreview),
              matching: find.byType(Container),
            );
            expect(previewFinder, findsOneWidget);

            final actualSize = tester.getSize(previewFinder);
            final expectedAspect = logicalSize.width / logicalSize.height;
            final actualAspect = actualSize.width / actualSize.height;

            expect(
              actualAspect,
              closeTo(expectedAspect, 1e-3),
              reason:
                  'Aspect ratio for mode $mode (isVertical=$isVertical) must match logical aspect',
            );

            expect(
              actualSize.width,
              lessThanOrEqualTo(360.0 + 1e-3),
              reason:
                  'Actual preview width for mode $mode (isVertical=$isVertical) must fit inside phone container width',
            );
          }
        }
      },
    );

    testWidgets('Phase3VisualQaPage checklist toggle updates count', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Phase3VisualQaPage()));

      expect(find.text('Verified: 0 / 19'), findsOneWidget);
      expect(find.text('HUMAN VERIFICATION: PENDING'), findsOneWidget);

      // Switch to checklist tab (tab 4)
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();

      expect(find.text('Verified: 0 / 19'), findsWidgets);

      // Find first checkbox and tap it
      final checkboxFinder = find.byType(Checkbox).first;
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      expect(find.text('Verified: 1 / 19'), findsWidgets);
      expect(find.text('VERIFIED'), findsOneWidget);
    });

    testWidgets(
      'Phase3VisualQaPage overflow test across modes and orientations',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: Phase3VisualQaPage()));
        await tester.pump();

        expect(tester.takeException(), isNull);

        final switchFinder = find.byType(Switch);
        await tester.tap(switchFinder);
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
