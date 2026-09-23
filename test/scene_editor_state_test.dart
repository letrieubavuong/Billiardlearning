// Tests for SceneEditorState immutability and copyWith
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/application/scene_editor/scene_editor_selection.dart';
import 'package:libre2026/application/scene_editor/scene_editor_state.dart';
import 'package:libre2026/application/scene_editor/scene_editor_tool.dart';

void main() {
  group('SceneEditorState Unit Tests', () {
    test('default state constructor initializes clean baseline', () {
      final now = DateTime.utc(2026, 9, 23);
      final scene = BilliardScene(
        id: 'scene-1',
        name: 'Test Scene',
        createdAt: now,
        updatedAt: now,
      );

      final state = SceneEditorState(scene: scene);

      expect(state.scene, equals(scene));
      expect(state.activeTool, equals(SceneEditorTool.select));
      expect(state.selection, equals(const SceneEditorSelection.none()));
      expect(state.isDirty, isFalse);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
      expect(state.errorMessage, isNull);
    });

    test(
      'copyWith updates specified fields while keeping unchanged fields',
      () {
        final now = DateTime.utc(2026, 9, 23);
        final initialScene = BilliardScene(
          id: 'scene-1',
          name: 'Test Scene',
          createdAt: now,
          updatedAt: now,
        );

        final state = SceneEditorState(scene: initialScene);

        final updatedState = state.copyWith(
          activeTool: SceneEditorTool.ball,
          selection: const SceneEditorSelection.ball('ball-1'),
          isDirty: true,
          canUndo: true,
        );

        expect(updatedState.scene, equals(initialScene));
        expect(updatedState.activeTool, equals(SceneEditorTool.ball));
        expect(
          updatedState.selection,
          equals(const SceneEditorSelection.ball('ball-1')),
        );
        expect(updatedState.isDirty, isTrue);
        expect(updatedState.canUndo, isTrue);
        expect(updatedState.canRedo, isFalse);
      },
    );

    test('equality and hashCode semantics', () {
      final now = DateTime.utc(2026, 9, 23);
      final scene = BilliardScene(
        id: 'scene-1',
        name: 'Test Scene',
        createdAt: now,
        updatedAt: now,
      );

      final state1 = SceneEditorState(
        scene: scene,
        activeTool: SceneEditorTool.move,
      );
      final state2 = SceneEditorState(
        scene: scene,
        activeTool: SceneEditorTool.move,
      );
      final state3 = SceneEditorState(
        scene: scene,
        activeTool: SceneEditorTool.delete,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(state3)));
    });
  });
}
