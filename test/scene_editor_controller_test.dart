// Comprehensive Unit Tests for SceneEditorController (Phase 4A)
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';
import 'package:libre2026/application/scene_editor/scene_editor_controller.dart';
import 'package:libre2026/application/scene_editor/scene_editor_selection.dart';
import 'package:libre2026/application/scene_editor/scene_editor_tool.dart';

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
      expect(controller.state.selection, equals(const SceneEditorSelection.none()));
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
      expect(controller.state.selection, equals(const SceneEditorSelection.ball('ball-1')));
      expect(controller.state.canUndo, isFalse);

      controller.clearSelection();
      expect(controller.state.selection, equals(const SceneEditorSelection.none()));
    });

    // --- SCENE IMMUTABILITY & COPY-ON-WRITE ---

    test('editing scene produces new BilliardScene leaving original scene unchanged', () {
      final initialScene = BilliardScene(
        id: 'scene-1',
        name: 'Original Scene',
        balls: const [
          BallPosition(id: 'b1', ballType: 'white', position: TablePoint(0.5, 0.5)),
        ],
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      final controller = SceneEditorController(initialScene: initialScene, clock: clock);

      controller.addBall(
        ballType: 'red',
        position: const TablePoint(0.2, 0.2),
      );

      expect(initialScene.balls.length, equals(1));
      expect(controller.currentScene.balls.length, equals(2));
      expect(controller.currentScene.id, equals(initialScene.id));
      expect(controller.currentScene.createdAt, equals(initialScene.createdAt));
      expect(controller.currentScene, isNot(same(initialScene)));
    });

    // --- BALL OPERATIONS ---

    test('ball CRUD operations, boundary clamping, ghost and extra ball semantics', () {
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
      expect(controller.state.selection, equals(SceneEditorSelection.ball(ball1.id)));

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
      final movedBall = controller.currentScene.balls.firstWhere((b) => b.id == ball1.id);
      expect(movedBall.position, equals(const TablePoint(0.0, 1.0)));

      // Update ball
      final updatedBallSpec = BallPosition(
        id: ball1.id,
        ballType: 'yellow',
        position: const TablePoint(0.6, 0.6),
        label: 'Bi Vàng',
      );
      controller.updateBall(updatedBallSpec);
      final updatedBall = controller.currentScene.balls.firstWhere((b) => b.id == ball1.id);
      expect(updatedBall.ballType, equals('yellow'));
      expect(updatedBall.position, equals(const TablePoint(0.6, 0.6)));

      // Delete ball
      controller.deleteBall(ball1.id);
      expect(controller.currentScene.balls.any((b) => b.id == ball1.id), isFalse);
    });

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
      expect(controller.state.selection, equals(SceneEditorSelection.trajectory(traj.id)));

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
      expect(controller.currentScene.trajectories.first.colorHex, equals('#FFFF00'));

      // Remove trajectory point
      controller.removeTrajectoryPoint(traj.id, 0);
      expect(controller.currentScene.trajectories.first.points.length, equals(2));

      // Delete trajectory
      controller.deleteTrajectory(traj.id);
      expect(controller.currentScene.trajectories.isEmpty, isTrue);
    });

    // --- ANNOTATION OPERATIONS ---

    test('annotation CRUD operations, degrees rotation, role and cushionSide preservation', () {
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
      expect(controller.state.selection, equals(SceneEditorSelection.annotation(ann.id)));

      // Move annotation
      controller.moveAnnotation(ann.id, const TablePoint(0.6, 0.0));
      expect(controller.currentScene.annotations.first.position, equals(const TablePoint(0.6, 0.0)));

      // Edit annotation text
      controller.editAnnotationText(ann.id, 'Nút 30');
      expect(controller.currentScene.annotations.first.text, equals('Nút 30'));

      // Edit annotation rotation (degrees)
      controller.editAnnotationRotation(ann.id, 90.0);
      expect(controller.currentScene.annotations.first.rotation, equals(90.0));

      // Edit annotation color
      controller.editAnnotationColor(ann.id, '#00FFFF');
      expect(controller.currentScene.annotations.first.colorHex, equals('#00FFFF'));

      // Delete annotation
      controller.deleteAnnotation(ann.id);
      expect(controller.currentScene.annotations.isEmpty, isTrue);
    });

    // --- PRESENTATION CONFIG OPERATIONS ---

    test('update presentation config preserves legacy system and view type indices', () {
      final controller = SceneEditorController(clock: clock);

      // Default presentation config
      expect(controller.currentScene.presentationConfig?.legacySystemIndex, equals(0));
      expect(controller.currentScene.presentationConfig?.legacyViewTypeIndex, equals(0));

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
    });

    // --- UNDO / REDO & NO-OP HISTORY ---

    test('undo, redo, divergent edit branch clearing, and no-op history filtering', () {
      final controller = SceneEditorController(clock: clock);

      // Edit 1: Add ball
      controller.addBall(ballType: 'red', position: const TablePoint(0.5, 0.5));
      final ball1Id = controller.currentScene.balls.first.id;
      expect(controller.state.canUndo, isTrue);

      // Edit 2: Move ball
      controller.moveBall(ball1Id, const TablePoint(0.7, 0.7));
      expect(controller.currentScene.balls.first.position, equals(const TablePoint(0.7, 0.7)));

      // No-op edit: move ball to exact same position -> must NOT push undo history
      final undoCountBeforeNoOp = controller.state.canUndo;
      controller.moveBall(ball1Id, const TablePoint(0.7, 0.7)); // Same position
      expect(controller.state.canUndo, equals(undoCountBeforeNoOp));

      // Undo 1: Reverts move
      controller.undo();
      expect(controller.currentScene.balls.first.position, equals(const TablePoint(0.5, 0.5)));
      expect(controller.state.canRedo, isTrue);

      // Divergent Edit: Add annotation while redo stack is non-empty -> clears redo branch
      controller.addAnnotation(text: 'Divergent', position: const TablePoint(0.1, 0.1));
      expect(controller.state.canRedo, isFalse);

      // Undo divergent edit
      controller.undo();
      expect(controller.currentScene.annotations.isEmpty, isTrue);
    });

    // --- DIRTY STATE TRACKING ---

    test('isDirty state transitions on load, edit, markSaved, and undo to saved baseline', () {
      final controller = SceneEditorController(clock: clock);

      // Initial clean state
      expect(controller.state.isDirty, isFalse);

      // Edit 1: Content change -> dirty
      controller.addBall(ballType: 'red', position: const TablePoint(0.5, 0.5));
      expect(controller.state.isDirty, isTrue);

      // Mark saved -> clean
      controller.markSaved();
      expect(controller.state.isDirty, isFalse);

      // Edit 2: Content change -> dirty
      controller.addAnnotation(text: 'Test', position: const TablePoint(0.2, 0.2));
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
    });
  });
}
