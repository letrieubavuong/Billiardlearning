// Comprehensive Unit Tests for SceneEditorController (Phase 4A)
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/application/scene_editor/scene_editor_controller.dart';
import 'package:libre2026/application/scene_editor/scene_editor_exception.dart';
import 'package:libre2026/application/scene_editor/scene_editor_selection.dart';
import 'package:libre2026/application/scene_editor/scene_editor_tool.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';

void main() {
  group('SceneEditorController Unit Tests', () {
    late DateTime fixedTime;
    late DateTime Function() clock;

    setUp(() {
      fixedTime = DateTime.utc(2026, 9, 23, 10, 0, 0);
      clock = () => fixedTime;
    });

    test('initialization with default or custom scene', () {
      final controller = SceneEditorController(clock: clock);

      expect(controller.state.scene.name, equals('Mặt bàn mới'));
      expect(controller.state.activeTool, equals(SceneEditorTool.select));
      expect(
        controller.state.selection,
        equals(const SceneEditorSelection.none()),
      );
      expect(controller.state.isDirty, isFalse);
      expect(controller.state.canUndo, isFalse);
      expect(controller.state.canRedo, isFalse);
    });

    test('tool and selection updates do not push undo history', () {
      final controller = SceneEditorController(clock: clock);

      controller.setTool(SceneEditorTool.ball);
      expect(controller.state.activeTool, equals(SceneEditorTool.ball));
      expect(controller.state.canUndo, isFalse);

      controller.select(const SceneEditorSelection.ball('ball-1'));
      expect(
        controller.state.selection,
        equals(const SceneEditorSelection.none()),
      ); // ball-1 does not exist in scene!
      expect(controller.state.canUndo, isFalse);

      controller.clearSelection();
      expect(
        controller.state.selection,
        equals(const SceneEditorSelection.none()),
      );
    });

    // --- SCENE IMMUTABILITY & COPY-ON-WRITE ---

    test(
      'editing scene produces new BilliardScene leaving original scene unchanged',
      () {
        final initialScene = BilliardScene(
          id: 'scene-1',
          name: 'Original Scene',
          balls: const [
            BallPosition(
              id: 'b1',
              ballType: 'white',
              position: TablePoint(0.5, 0.5),
            ),
          ],
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        final controller = SceneEditorController(
          initialScene: initialScene,
          clock: clock,
        );

        controller.addBall(
          ballType: 'red',
          position: const TablePoint(0.2, 0.2),
        );

        expect(initialScene.balls.length, equals(1));
        expect(controller.currentScene.balls.length, equals(2));
        expect(controller.currentScene.id, equals(initialScene.id));
        expect(
          controller.currentScene.createdAt,
          equals(initialScene.createdAt),
        );
        expect(controller.currentScene, isNot(same(initialScene)));
      },
    );

    // --- BALL OPERATIONS ---

    test(
      'ball CRUD operations, boundary clamping, ghost and extra ball semantics',
      () {
        final controller = SceneEditorController(clock: clock);

        // Add regular ball
        controller.addBall(
          ballType: 'red',
          position: const TablePoint(0.5, 0.5),
          label: 'Bi Đỏ',
          colorHex: '#FF0000',
        );

        expect(controller.currentScene.balls.length, equals(1));
        final ball1 = controller.currentScene.balls.first;
        expect(ball1.ballType, equals('red'));
        expect(ball1.position, equals(const TablePoint(0.5, 0.5)));
        expect(ball1.label, equals('Bi Đỏ'));
        expect(ball1.id, isNotEmpty);
        expect(
          controller.state.selection,
          equals(SceneEditorSelection.ball(ball1.id)),
        );

        // Add ghost ball: ballType == 'ghost'
        controller.addBall(
          ballType: 'ghost',
          position: const TablePoint(0.3, 0.3),
          legacyType: 1, // legacy half type
        );
        final ghostBall = controller.currentScene.balls.last;
        expect(ghostBall.ballType, equals('ghost'));

        // Add numbered extra ball: ballType == 'extra' with legacyType == 1 (must NOT be ghost)
        controller.addBall(
          ballType: 'extra',
          position: const TablePoint(0.4, 0.4),
          label: '8',
          legacyType: 1,
        );
        final extraBall = controller.currentScene.balls.last;
        expect(extraBall.ballType, equals('extra'));
        expect(extraBall.legacyType, equals(1));

        // Move ball with position boundary clamping (out of bounds -> clamped [0, 1])
        controller.moveBall(ball1.id, const TablePoint(-0.2, 1.5));
        final movedBall = controller.currentScene.balls.firstWhere(
          (b) => b.id == ball1.id,
        );
        expect(movedBall.position, equals(const TablePoint(0.0, 1.0)));

        // Update ball
        final updatedBallSpec = BallPosition(
          id: ball1.id,
          ballType: 'yellow',
          position: const TablePoint(0.6, 0.6),
          label: 'Bi Vàng',
        );
        controller.updateBall(updatedBallSpec);
        final updatedBall = controller.currentScene.balls.firstWhere(
          (b) => b.id == ball1.id,
        );
        expect(updatedBall.ballType, equals('yellow'));
        expect(updatedBall.position, equals(const TablePoint(0.6, 0.6)));

        // Delete ball
        controller.deleteBall(ball1.id);
        expect(
          controller.currentScene.balls.any((b) => b.id == ball1.id),
          isFalse,
        );
      },
    );

    // --- TRAJECTORY OPERATIONS ---

    test('trajectory CRUD operations and color preservation', () {
      final controller = SceneEditorController(clock: clock);

      // Add trajectory
      controller.addTrajectory(
        colorHex: '#00FF00',
        points: const [TablePoint(0.1, 0.1), TablePoint(0.5, 0.5)],
      );

      expect(controller.currentScene.trajectories.length, equals(1));
      final traj = controller.currentScene.trajectories.first;
      expect(traj.colorHex, equals('#00FF00'));
      expect(traj.points.length, equals(2));
      expect(
        controller.state.selection,
        equals(SceneEditorSelection.trajectory(traj.id)),
      );

      // Add trajectory point
      controller.addTrajectoryPoint(traj.id, const TablePoint(0.9, 0.9));
      final trajAfterAdd = controller.currentScene.trajectories.first;
      expect(trajAfterAdd.points.length, equals(3));
      expect(trajAfterAdd.points.last, equals(const TablePoint(0.9, 0.9)));

      // Move trajectory point with clamping
      controller.moveTrajectoryPoint(traj.id, 1, const TablePoint(0.6, 0.6));
      final trajAfterMove = controller.currentScene.trajectories.first;
      expect(trajAfterMove.points[1], equals(const TablePoint(0.6, 0.6)));

      // Change trajectory color hex
      controller.changeTrajectoryColorHex(traj.id, '#FFFF00');
      expect(
        controller.currentScene.trajectories.first.colorHex,
        equals('#FFFF00'),
      );

      // Remove trajectory point
      controller.removeTrajectoryPoint(traj.id, 0);
      expect(
        controller.currentScene.trajectories.first.points.length,
        equals(2),
      );

      // Delete trajectory
      controller.deleteTrajectory(traj.id);
      expect(controller.currentScene.trajectories.isEmpty, isTrue);
    });

    // --- ANNOTATION OPERATIONS ---

    test(
      'annotation CRUD operations, degrees rotation, role and cushionSide preservation',
      () {
        final controller = SceneEditorController(clock: clock);

        // Add annotation
        controller.addAnnotation(
          text: 'Nút 20',
          position: const TablePoint(0.5, 0.0),
          colorHex: '#FFCC00',
          rotation: 45.0,
          role: 'cushionNumber',
          cushionSide: 'top',
        );

        expect(controller.currentScene.annotations.length, equals(1));
        final ann = controller.currentScene.annotations.first;
        expect(ann.text, equals('Nút 20'));
        expect(ann.position, equals(const TablePoint(0.5, 0.0)));
        expect(ann.colorHex, equals('#FFCC00'));
        expect(ann.rotation, equals(45.0)); // Degrees
        expect(ann.role, equals('cushionNumber'));
        expect(ann.cushionSide, equals('top'));
        expect(
          controller.state.selection,
          equals(SceneEditorSelection.annotation(ann.id)),
        );

        // Move annotation
        controller.moveAnnotation(ann.id, const TablePoint(0.6, 0.0));
        expect(
          controller.currentScene.annotations.first.position,
          equals(const TablePoint(0.6, 0.0)),
        );

        // Edit annotation text
        controller.editAnnotationText(ann.id, 'Nút 30');
        expect(
          controller.currentScene.annotations.first.text,
          equals('Nút 30'),
        );

        // Edit annotation rotation (degrees)
        controller.editAnnotationRotation(ann.id, 90.0);
        expect(
          controller.currentScene.annotations.first.rotation,
          equals(90.0),
        );

        // Edit annotation color
        controller.editAnnotationColor(ann.id, '#00FFFF');
        expect(
          controller.currentScene.annotations.first.colorHex,
          equals('#00FFFF'),
        );

        // Delete annotation
        controller.deleteAnnotation(ann.id);
        expect(controller.currentScene.annotations.isEmpty, isTrue);
      },
    );

    // --- PRESENTATION CONFIG OPERATIONS ---

    test(
      'update presentation config preserves legacy system and view type indices',
      () {
        final controller = SceneEditorController(clock: clock);

        // Default presentation config
        expect(
          controller.currentScene.presentationConfig?.legacySystemIndex,
          equals(0),
        );
        expect(
          controller.currentScene.presentationConfig?.legacyViewTypeIndex,
          equals(0),
        );

        // Update presentation config to Xô hai băng (4) and Half view (1)
        controller.updatePresentationConfig(
          legacySystemIndex: 4,
          legacyViewTypeIndex: 1,
          labelFontSize: 16.0,
        );

        final config = controller.currentScene.presentationConfig;
        expect(config?.legacySystemIndex, equals(4));
        expect(config?.legacyViewTypeIndex, equals(1));
        expect(config?.labelFontSize, equals(16.0));
      },
    );

    // --- UNDO / REDO & NO-OP HISTORY ---

    test(
      'undo, redo, divergent edit branch clearing, and no-op history filtering',
      () {
        final controller = SceneEditorController(clock: clock);

        // Edit 1: Add ball
        controller.addBall(
          ballType: 'red',
          position: const TablePoint(0.5, 0.5),
        );
        final ball1Id = controller.currentScene.balls.first.id;
        expect(controller.state.canUndo, isTrue);

        // Edit 2: Move ball
        controller.moveBall(ball1Id, const TablePoint(0.7, 0.7));
        expect(
          controller.currentScene.balls.first.position,
          equals(const TablePoint(0.7, 0.7)),
        );

        // No-op edit: move ball to exact same position -> must NOT push undo history
        final undoCountBeforeNoOp = controller.state.canUndo;
        controller.moveBall(
          ball1Id,
          const TablePoint(0.7, 0.7),
        ); // Same position
        expect(controller.state.canUndo, equals(undoCountBeforeNoOp));

        // Undo 1: Reverts move
        controller.undo();
        expect(
          controller.currentScene.balls.first.position,
          equals(const TablePoint(0.5, 0.5)),
        );
        expect(controller.state.canRedo, isTrue);

        // Divergent Edit: Add annotation while redo stack is non-empty -> clears redo branch
        controller.addAnnotation(
          text: 'Divergent',
          position: const TablePoint(0.1, 0.1),
        );
        expect(controller.state.canRedo, isFalse);

        // Undo divergent edit
        controller.undo();
        expect(controller.currentScene.annotations.isEmpty, isTrue);
      },
    );

    // --- DIRTY STATE TRACKING ---

    test(
      'isDirty state transitions on load, edit, markSaved, and undo to saved baseline',
      () {
        final controller = SceneEditorController(clock: clock);

        // Initial clean state
        expect(controller.state.isDirty, isFalse);

        // Edit 1: Content change -> dirty
        controller.addBall(
          ballType: 'red',
          position: const TablePoint(0.5, 0.5),
        );
        expect(controller.state.isDirty, isTrue);

        // Mark saved -> clean
        controller.markSaved();
        expect(controller.state.isDirty, isFalse);

        // Edit 2: Content change -> dirty
        controller.addAnnotation(
          text: 'Test',
          position: const TablePoint(0.2, 0.2),
        );
        expect(controller.state.isDirty, isTrue);

        // Undo back to saved baseline -> clean!
        controller.undo();
        expect(controller.state.isDirty, isFalse);

        // Redo -> dirty again
        controller.redo();
        expect(controller.state.isDirty, isTrue);

        // Load new scene -> resets baseline to clean
        final newScene = BilliardScene(
          id: 'loaded-scene',
          name: 'Loaded Scene',
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );
        controller.loadScene(newScene);

        expect(controller.currentScene.name, equals('Loaded Scene'));
        expect(controller.state.isDirty, isFalse);
        expect(controller.state.canUndo, isFalse);
        expect(controller.state.canRedo, isFalse);
      },
    );

    // ==================================================
    // EXTERNAL REVIEW HARDENING REGRESSION TESTS (A - J)
    // ==================================================

    test('A. default initial scene is created exactly once semantically', () {
      final controller = SceneEditorController(clock: clock);

      final initialId = controller.currentScene.id;
      expect(initialId, isNotEmpty);
      expect(controller.state.isDirty, isFalse);

      // Verify state scene id equals baseline initial scene id
      controller.addBall(
        ballType: 'white',
        position: const TablePoint(0.1, 0.1),
      );
      expect(controller.state.isDirty, isTrue);

      controller.undo();
      expect(controller.state.isDirty, isFalse);
      expect(controller.currentScene.id, equals(initialId));
    });

    test('B. initial dirty baseline test sequence (Requirement 2)', () {
      final controller = SceneEditorController(clock: clock);
      final originalId = controller.currentScene.id;

      expect(controller.state.isDirty, isFalse);

      controller.addBall(ballType: 'red', position: const TablePoint(0.5, 0.5));
      expect(controller.state.isDirty, isTrue);

      controller.undo();
      expect(controller.state.isDirty, isFalse);
      expect(controller.currentScene.id, equals(originalId));

      controller.redo();
      expect(controller.state.isDirty, isTrue);
    });

    test(
      'C. updateBall no-op detection and semantic edit checks (Requirement 6)',
      () {
        final initialScene = BilliardScene(
          id: 'scene-1',
          name: 'Scene with Ball',
          balls: const [
            BallPosition(
              id: 'b1',
              ballType: 'red',
              position: TablePoint(0.5, 0.5),
              label: 'Original',
            ),
          ],
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        final controller = SceneEditorController(
          initialScene: initialScene,
          clock: clock,
        );

        final ballId = 'b1';
        final updatedAtBefore = controller.currentScene.updatedAt;

        // Call updateBall with identical values (new instance of BallPosition with same values)
        final identicalBall = const BallPosition(
          id: 'b1',
          ballType: 'red',
          position: TablePoint(0.5, 0.5),
          label: 'Original',
        );

        controller.updateBall(identicalBall);

        expect(controller.state.isDirty, isFalse);
        expect(controller.state.canUndo, isFalse);
        expect(controller.currentScene.updatedAt, equals(updatedAtBefore));

        // Call updateBall with changed field
        final changedBall = BallPosition(
          id: ballId,
          ballType: 'red',
          position: const TablePoint(0.5, 0.5),
          label: 'Changed Label',
        );

        controller.updateBall(changedBall);

        expect(controller.state.isDirty, isTrue);
        expect(controller.state.canUndo, isTrue);
        expect(
          controller.currentScene.balls.first.label,
          equals('Changed Label'),
        );
      },
    );

    test(
      'D. input mutable lists cannot mutate editor state (Requirement 4)',
      () {
        final inputBalls = <BallPosition>[
          const BallPosition(
            id: 'b1',
            ballType: 'white',
            position: TablePoint(0.1, 0.1),
          ),
        ];

        final scene = BilliardScene(
          id: 'input-scene',
          name: 'Input Scene',
          balls: inputBalls,
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        final controller = SceneEditorController(clock: clock);
        controller.loadScene(scene);

        inputBalls.clear();

        expect(controller.currentScene.balls.length, equals(1));
        expect(controller.currentScene.balls.first.id, equals('b1'));
      },
    );

    test(
      'E & F. output collections and nested points are immutable snapshots (Requirement 3)',
      () {
        final controller = SceneEditorController(clock: clock);
        controller.addTrajectory(
          colorHex: '#FFFFFF',
          points: const [TablePoint(0.1, 0.1), TablePoint(0.5, 0.5)],
        );

        // Check direct scene collections immutability
        expect(
          () => controller.currentScene.balls.add(
            const BallPosition(
              id: 'hack',
              ballType: 'red',
              position: TablePoint(0.1, 0.1),
            ),
          ),
          throwsUnsupportedError,
        );

        expect(
          () => controller.currentScene.trajectories.add(
            const TrajectoryLine(id: 'hack'),
          ),
          throwsUnsupportedError,
        );

        // Check nested trajectory points immutability
        expect(
          () => controller.currentScene.trajectories.first.points.add(
            const TablePoint(0.9, 0.9),
          ),
          throwsUnsupportedError,
        );
      },
    );

    test('G. selection sanitized after undo and redo (Requirement 8 & 9)', () {
      final controller = SceneEditorController(clock: clock);

      // Add ball (creates selection for new ball)
      controller.addBall(ballType: 'red', position: const TablePoint(0.5, 0.5));
      final ballId = controller.currentScene.balls.first.id;
      expect(controller.state.selection.targetId, equals(ballId));

      // Undo removes ball -> selection MUST become none
      controller.undo();
      expect(controller.currentScene.balls, isEmpty);
      expect(
        controller.state.selection,
        equals(const SceneEditorSelection.none()),
      );

      // Redo restores ball -> selection restored properly without invalid reference
      controller.redo();
      expect(controller.currentScene.balls.length, equals(1));
    });

    test(
      'H. trajectoryPoint selection sanitized after point removal (Requirement 9)',
      () {
        final controller = SceneEditorController(clock: clock);
        controller.addTrajectory(
          points: const [
            TablePoint(0.1, 0.1),
            TablePoint(0.5, 0.5),
            TablePoint(0.9, 0.9),
          ],
        );

        final trajId = controller.currentScene.trajectories.first.id;

        // Select point at index 2
        controller.select(SceneEditorSelection.trajectoryPoint(trajId, 2));
        expect(controller.state.selection.pointIndex, equals(2));

        // Remove point at index 2
        controller.removeTrajectoryPoint(trajId, 2);

        // Selection must become valid or none (point index 2 is now out of bounds for 2-element array)
        expect(
          controller.state.selection,
          equals(const SceneEditorSelection.none()),
        );
      },
    );

    test(
      'I. missing target operations follow explicit SceneEditorException policy (Requirement 10 & 11)',
      () {
        final controller = SceneEditorController(clock: clock);

        expect(
          () => controller.moveBall('non-existent', const TablePoint(0.5, 0.5)),
          throwsA(isA<SceneEditorTargetNotFoundException>()),
        );

        expect(
          () => controller.updateBall(
            const BallPosition(
              id: 'non-existent',
              ballType: 'red',
              position: TablePoint(0.1, 0.1),
            ),
          ),
          throwsA(isA<SceneEditorTargetNotFoundException>()),
        );

        expect(
          () => controller.deleteBall('non-existent'),
          throwsA(isA<SceneEditorTargetNotFoundException>()),
        );

        expect(
          () => controller.addTrajectoryPoint(
            'non-existent',
            const TablePoint(0.1, 0.1),
          ),
          throwsA(isA<SceneEditorTargetNotFoundException>()),
        );

        expect(
          () => controller.deleteTrajectory('non-existent'),
          throwsA(isA<SceneEditorTargetNotFoundException>()),
        );

        expect(
          () => controller.moveAnnotation(
            'non-existent',
            const TablePoint(0.1, 0.1),
          ),
          throwsA(isA<SceneEditorTargetNotFoundException>()),
        );

        // Trajectory point out of range
        controller.addTrajectory(points: const [TablePoint(0.1, 0.1)]);
        final trajId = controller.currentScene.trajectories.first.id;

        expect(
          () => controller.moveTrajectoryPoint(
            trajId,
            5,
            const TablePoint(0.2, 0.2),
          ),
          throwsA(isA<SceneEditorInvalidOperationException>()),
        );

        expect(
          () => controller.removeTrajectoryPoint(trajId, -1),
          throwsA(isA<SceneEditorInvalidOperationException>()),
        );
      },
    );

    // ==================================================
    // FINAL HARDENING REGRESSION TESTS (TEACHING TIMELINE & POINT SELECTION DRIFT)
    // ==================================================

    test(
      'teachingTimeline input alias mutation cannot leak into editor state (Requirement 4)',
      () {
        final steps = <dynamic>[
          {'name': 'A'},
        ];
        final timeline = <String, dynamic>{'steps': steps};

        final scene = BilliardScene(
          id: 'timeline-scene',
          name: 'Timeline Scene',
          teachingTimeline: timeline,
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        final controller = SceneEditorController(clock: clock);
        controller.loadScene(scene);

        // Mutate original caller structures
        timeline['other'] = true;
        steps.clear();

        final currentTimeline = controller.currentScene.teachingTimeline!;
        expect(currentTimeline.containsKey('other'), isFalse);
        final currentSteps = currentTimeline['steps'] as List;
        expect(currentSteps.length, equals(1));
        expect((currentSteps.first as Map)['name'], equals('A'));
      },
    );

    test(
      'teachingTimeline output collections and nested objects are immutable snapshots (Requirement 5)',
      () {
        final scene = BilliardScene(
          id: 'timeline-scene',
          name: 'Timeline Scene',
          teachingTimeline: {
            'steps': [
              {'name': 'Step 1'},
            ],
          },
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        final controller = SceneEditorController(
          initialScene: scene,
          clock: clock,
        );

        // Attempt root map mutation
        expect(
          () => controller.currentScene.teachingTimeline!['x'] = 1,
          throwsUnsupportedError,
        );

        // Attempt nested list mutation
        final steps =
            controller.currentScene.teachingTimeline!['steps'] as List;
        expect(() => steps.add({'name': 'Step 2'}), throwsUnsupportedError);

        // Attempt nested map mutation
        final step = steps.first as Map;
        expect(() => step['x'] = 1, throwsUnsupportedError);
      },
    );

    test(
      'teachingTimeline deep semantic comparison for dirty state tracking (Requirement 6)',
      () {
        final timelineA = {
          'steps': [
            {'name': 'Step 1', 'power': 0.8},
          ],
        };
        final sceneA = BilliardScene(
          id: 'timeline-scene',
          name: 'Timeline Scene',
          teachingTimeline: timelineA,
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        final controller = SceneEditorController(
          initialScene: sceneA,
          clock: clock,
        );
        expect(controller.state.isDirty, isFalse);

        // Load equivalent timeline instantiated separately
        final timelineB = {
          'steps': [
            {'name': 'Step 1', 'power': 0.8},
          ],
        };
        final sceneB = BilliardScene(
          id: 'timeline-scene',
          name: 'Timeline Scene',
          teachingTimeline: timelineB,
          createdAt: fixedTime,
          updatedAt: fixedTime,
        );

        controller.loadScene(sceneB);
        expect(controller.state.isDirty, isFalse);
      },
    );

    test(
      'trajectoryPoint selection tracks index shift accurately on removal (Requirement 8)',
      () {
        final controller = SceneEditorController(clock: clock);
        controller.addTrajectory(
          points: const [
            TablePoint(0.1, 0.1), // A (index 0)
            TablePoint(0.3, 0.3), // B (index 1)
            TablePoint(0.5, 0.5), // C (index 2)
            TablePoint(0.7, 0.7), // D (index 3)
          ],
        );

        final trajId = controller.currentScene.trajectories.first.id;

        // 1. Remove BEFORE selected point (select C at index 2, remove B at index 1)
        controller.select(SceneEditorSelection.trajectoryPoint(trajId, 2));
        expect(controller.state.selection.pointIndex, equals(2));

        controller.removeTrajectoryPoint(trajId, 1);
        // selection index shifts from 2 to 1 (still pointing to C)
        expect(
          controller.state.selection.type,
          equals(SceneEditorSelectionType.trajectoryPoint),
        );
        expect(controller.state.selection.pointIndex, equals(1));
        expect(
          controller.currentScene.trajectories.first.points[1],
          equals(const TablePoint(0.5, 0.5)),
        );

        // 2. Remove SELECTED point (select C at index 1, remove C at index 1)
        controller.removeTrajectoryPoint(trajId, 1);
        // selection becomes none
        expect(
          controller.state.selection,
          equals(const SceneEditorSelection.none()),
        );

        // 3. Remove AFTER selected point (select A at index 0, remove D at index 1)
        controller.select(SceneEditorSelection.trajectoryPoint(trajId, 0));
        expect(controller.state.selection.pointIndex, equals(0));

        controller.removeTrajectoryPoint(trajId, 1);
        // selection remains index 0
        expect(
          controller.state.selection.type,
          equals(SceneEditorSelectionType.trajectoryPoint),
        );
        expect(controller.state.selection.pointIndex, equals(0));
      },
    );

    test(
      'undo and redo clear trajectoryPoint selection for safety (Requirement 9 & 10)',
      () {
        final controller = SceneEditorController(clock: clock);
        controller.addTrajectory(
          points: const [
            TablePoint(0.1, 0.1), // A (index 0)
            TablePoint(0.3, 0.3), // B (index 1)
            TablePoint(0.5, 0.5), // C (index 2)
          ],
        );

        final trajId = controller.currentScene.trajectories.first.id;

        // Select point B at index 1
        controller.select(SceneEditorSelection.trajectoryPoint(trajId, 1));
        expect(controller.state.selection.pointIndex, equals(1));

        // Remove A at index 0 (points become [B, C], B shifts to index 0)
        controller.removeTrajectoryPoint(trajId, 0);
        expect(controller.state.selection.pointIndex, equals(0));

        // Undo removes edit and restores [A, B, C] -> point selection MUST be cleared to none
        controller.undo();
        expect(
          controller.state.selection,
          equals(const SceneEditorSelection.none()),
        );

        // Redo restores [B, C] -> point selection MUST remain none
        controller.redo();
        expect(
          controller.state.selection,
          equals(const SceneEditorSelection.none()),
        );
      },
    );
  });
}
