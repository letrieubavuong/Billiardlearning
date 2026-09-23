import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/application/scene_editor/scene_editor_controller.dart';
import 'package:libre2026/application/scene_editor/scene_editor_persistence_coordinator.dart';
import 'package:libre2026/application/scene_editor/scene_editor_selection.dart';
import 'package:libre2026/application/scene_editor/scene_editor_tool.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/repositories/repositories.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';

class MockCountingSceneRepository implements VNextSceneRepository {
  final Map<String, BilliardScene> storage = {};
  int saveCount = 0;
  bool shouldFailSave = false;

  @override
  Future<BilliardScene?> getById(
    String id, {
    bool includeDeleted = false,
  }) async {
    return storage[id];
  }

  @override
  Future<List<BilliardScene>> list({bool includeDeleted = false}) async {
    return storage.values.toList();
  }

  @override
  Future<void> save(BilliardScene scene) async {
    if (shouldFailSave) {
      throw Exception('Simulated Autosave Write Exception');
    }
    saveCount++;
    storage[scene.id] = scene;
  }

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> restore(String id) async {}

  @override
  Future<void> purge(String id) async {}
}

void main() {
  late MockCountingSceneRepository repo;
  late SceneEditorController controller;
  late SceneEditorPersistenceCoordinator coordinator;

  setUp(() {
    repo = MockCountingSceneRepository();
    controller = SceneEditorController();
    coordinator = SceneEditorPersistenceCoordinator(
      repository: repo,
      controller: controller,
      debounceDuration: const Duration(milliseconds: 100),
    );
  });

  tearDown(() {
    coordinator.dispose();
  });

  test('rapid edits coalesce to a single repository save', () async {
    expect(repo.saveCount, equals(0));

    // Edit A
    controller.addBall(ballType: 'white', position: const TablePoint(0.1, 0.1));
    await Future.delayed(const Duration(milliseconds: 30));

    // Edit B
    controller.addBall(
      ballType: 'yellow',
      position: const TablePoint(0.2, 0.2),
    );
    await Future.delayed(const Duration(milliseconds: 30));

    // Edit C
    controller.addBall(ballType: 'red', position: const TablePoint(0.3, 0.3));

    // Wait past debounce duration
    await Future.delayed(const Duration(milliseconds: 150));

    expect(repo.saveCount, equals(1));
    expect(controller.state.isDirty, isFalse);
    expect(repo.storage[controller.currentScene.id]?.balls.length, equals(3));
  });

  test('tool switch and selection change do not trigger autosave', () async {
    controller.setTool(SceneEditorTool.trajectory);
    await Future.delayed(const Duration(milliseconds: 150));
    expect(repo.saveCount, equals(0));

    controller.select(const SceneEditorSelection.none());
    await Future.delayed(const Duration(milliseconds: 150));
    expect(repo.saveCount, equals(0));
  });

  test('content commit schedules autosave', () async {
    controller.addBall(ballType: 'white', position: const TablePoint(0.5, 0.5));
    expect(coordinator.hasPendingAutosave, isTrue);

    await Future.delayed(const Duration(milliseconds: 150));

    expect(repo.saveCount, equals(1));
    expect(controller.state.isDirty, isFalse);
  });

  test(
    'undoing back to clean state before timer fires prevents save',
    () async {
      controller.addBall(
        ballType: 'white',
        position: const TablePoint(0.5, 0.5),
      );
      expect(controller.state.isDirty, isTrue);

      // Undo back to saved baseline before 100ms timer fires
      controller.undo();
      expect(controller.state.isDirty, isFalse);

      await Future.delayed(const Duration(milliseconds: 150));

      // No repository write performed
      expect(repo.saveCount, equals(0));
    },
  );

  test(
    'autosave failure retains dirty state without throwing unhandled exceptions',
    () async {
      Object? reportedError;
      coordinator.dispose();

      coordinator = SceneEditorPersistenceCoordinator(
        repository: repo,
        controller: controller,
        debounceDuration: const Duration(milliseconds: 50),
        onError: (err, st) {
          reportedError = err;
        },
      );

      repo.shouldFailSave = true;

      controller.addBall(
        ballType: 'white',
        position: const TablePoint(0.5, 0.5),
      );
      await Future.delayed(const Duration(milliseconds: 100));

      expect(reportedError, isNotNull);
      expect(controller.state.isDirty, isTrue);
      expect(repo.saveCount, equals(0));
    },
  );

  test('dispose cancels pending autosave timer', () async {
    controller.addBall(ballType: 'white', position: const TablePoint(0.5, 0.5));
    coordinator.dispose();

    await Future.delayed(const Duration(milliseconds: 150));

    expect(repo.saveCount, equals(0));
  });

  test('flushPendingSave immediately saves pending dirty state', () async {
    controller.addBall(ballType: 'white', position: const TablePoint(0.5, 0.5));
    expect(repo.saveCount, equals(0));

    await coordinator.flushPendingSave();

    expect(repo.saveCount, equals(1));
    expect(controller.state.isDirty, isFalse);
  });
}
