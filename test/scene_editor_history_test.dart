// Tests for SceneEditorHistory stack, max history bound, and undo/redo behavior
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/application/scene_editor/scene_editor_history.dart';

void main() {
  group('SceneEditorHistory Stack Tests', () {
    late DateTime now;
    late BilliardScene sceneA;
    late BilliardScene sceneB;
    late BilliardScene sceneC;
    late BilliardScene sceneD;

    setUp(() {
      now = DateTime.utc(2026, 9, 23);
      sceneA = BilliardScene(
        id: '1',
        name: 'Scene A',
        createdAt: now,
        updatedAt: now,
      );
      sceneB = BilliardScene(
        id: '1',
        name: 'Scene B',
        createdAt: now,
        updatedAt: now,
      );
      sceneC = BilliardScene(
        id: '1',
        name: 'Scene C',
        createdAt: now,
        updatedAt: now,
      );
      sceneD = BilliardScene(
        id: '1',
        name: 'Scene D',
        createdAt: now,
        updatedAt: now,
      );
    });

    test('initial history stack is empty', () {
      final history = SceneEditorHistory();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.undoCount, equals(0));
      expect(history.redoCount, equals(0));
    });

    test('validates maxHistory <= 0 throws ArgumentError in release mode', () {
      expect(() => SceneEditorHistory(maxHistory: 0), throwsArgumentError);
      expect(() => SceneEditorHistory(maxHistory: -1), throwsArgumentError);
    });

    test('push adds to undo stack and clears redo stack', () {
      final history = SceneEditorHistory();
      history.push(sceneA);

      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
      expect(history.undoCount, equals(1));

      // Simulate undo to populate redo stack
      final undone = history.undo(sceneB);
      expect(undone, equals(sceneA));
      expect(history.canRedo, isTrue);
      expect(history.redoCount, equals(1));

      // Push new scene clears redo stack
      history.push(sceneC);
      expect(history.canRedo, isFalse);
      expect(history.redoCount, equals(0));
    });

    test('undo and redo sequence restores expected snapshots', () {
      final history = SceneEditorHistory();
      // Current is sceneC, undo stack has [sceneA, sceneB]
      history.push(sceneA);
      history.push(sceneB);

      // Undo 1: current sceneC -> pushed to redo; returns sceneB
      final res1 = history.undo(sceneC);
      expect(res1, equals(sceneB));

      // Undo 2: current sceneB -> pushed to redo; returns sceneA
      final res2 = history.undo(sceneB);
      expect(res2, equals(sceneA));

      // Undo when empty returns null
      final res3 = history.undo(sceneA);
      expect(res3, isNull);

      // Redo 1: current sceneA -> pushed to undo; returns sceneB
      final redo1 = history.redo(sceneA);
      expect(redo1, equals(sceneB));

      // Redo 2: current sceneB -> pushed to undo; returns sceneC
      final redo2 = history.redo(sceneB);
      expect(redo2, equals(sceneC));

      // Redo when empty returns null
      final redo3 = history.redo(sceneC);
      expect(redo3, isNull);
    });

    test('max history bound limit discards oldest snapshots', () {
      final history = SceneEditorHistory(maxHistory: 3);

      final s1 = BilliardScene(
        id: '1',
        name: 'S1',
        createdAt: now,
        updatedAt: now,
      );
      final s2 = BilliardScene(
        id: '1',
        name: 'S2',
        createdAt: now,
        updatedAt: now,
      );
      final s3 = BilliardScene(
        id: '1',
        name: 'S3',
        createdAt: now,
        updatedAt: now,
      );
      final s4 = BilliardScene(
        id: '1',
        name: 'S4',
        createdAt: now,
        updatedAt: now,
      );

      history.push(s1);
      history.push(s2);
      history.push(s3);
      history.push(s4); // Should evict s1

      expect(history.undoCount, equals(3));

      expect(history.undo(sceneD), equals(s4));
      expect(history.undo(s4), equals(s3));
      expect(history.undo(s3), equals(s2));
      expect(history.undo(s2), isNull); // s1 was evicted
    });

    test('clear resets history stack completely', () {
      final history = SceneEditorHistory();
      history.push(sceneA);
      history.push(sceneB);
      history.undo(sceneC);

      history.clear();

      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.undoCount, equals(0));
      expect(history.redoCount, equals(0));
    });
  });
}
