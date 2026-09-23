// Phase 4C Autosave Tests for SceneEditorPersistenceCoordinator

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre2026/application/scene_editor/scene_editor_controller.dart';
import 'package:libre2026/application/scene_editor/scene_editor_persistence_coordinator.dart';
import 'package:libre2026/application/scene_editor/scene_editor_selection.dart';
import 'package:libre2026/application/scene_editor/scene_editor_tool.dart';
import 'package:libre2026/domain/entities/entities.dart';
import 'package:libre2026/domain/repositories/repositories.dart';
import 'package:libre2026/domain/value_objects/value_objects.dart';

class ControllableCountingSceneRepository implements VNextSceneRepository {
  final Map<String, BilliardScene> storage = {};
  int saveCount = 0;
  int activeSaveCount = 0;
  int peakSaveCount = 0;
  Completer<void>? saveCompleter;
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
    activeSaveCount++;
    if (activeSaveCount > peakSaveCount) {
      peakSaveCount = activeSaveCount;
    }
    if (saveCompleter != null) {
      await saveCompleter!.future;
    }
    activeSaveCount--;
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
  late ControllableCountingSceneRepository repo;
  late SceneEditorController controller;
  late SceneEditorPersistenceCoordinator coordinator;

  setUp(() {
    repo = ControllableCountingSceneRepository();
    controller = SceneEditorController();
    coordinator = SceneEditorPersistenceCoordinator(
      repository: repo,
      controller: controller,
      debounceDuration: const Duration(milliseconds: 50),
    );
  });

  tearDown(() {
    coordinator.dispose();
  });

  test(
    'serialized writes guarantee maximum 1 concurrent repository.save write',
    () async {
      controller.addBall(
        ballType: 'white',
        position: const TablePoint(0.1, 0.1),
      );
      repo.saveCompleter = Completer<void>();

      // Trigger two saves concurrently
      final save1 = coordinator.save();
      final save2 = coordinator.save();

      // Verify peak active save count is 1
      expect(repo.peakSaveCount, equals(1));

      repo.saveCompleter!.complete();
      repo.saveCompleter = null;

      await save1;
      await save2;

      expect(repo.peakSaveCount, equals(1));
      expect(coordinator.maxConcurrentSaves, equals(1));
    },
  );

  test(
    'autosave in-flight edit: edit B -> blocked save B -> edit C -> finish B -> latest C persisted clean',
    () async {
      controller.addBall(
        ballType: 'white',
        position: const TablePoint(0.1, 0.1),
      );
      expect(controller.state.isDirty, isTrue);

      repo.saveCompleter = Completer<void>();
      await Future.delayed(
        const Duration(milliseconds: 80),
      ); // trigger autosave for B

      // Save for B is now in-flight and blocked
      expect(repo.activeSaveCount, equals(1));

      // While blocked, user performs edit C
      controller.addBall(
        ballType: 'yellow',
        position: const TablePoint(0.2, 0.2),
      );
      expect(controller.state.isDirty, isTrue);

      // Complete save B
      repo.saveCompleter!.complete();
      repo.saveCompleter = null;

      // Wait for follow-up debounced save of C
      await Future.delayed(const Duration(milliseconds: 150));

      expect(controller.state.isDirty, isFalse);
      expect(repo.storage[controller.currentScene.id]?.balls.length, equals(2));
    },
  );

  test(
    'dirty tool-switch debounce test: tool and selection changes do NOT postpone active autosave timer',
    () async {
      // Edit scene content -> dirty
      controller.addBall(
        ballType: 'white',
        position: const TablePoint(0.5, 0.5),
      );
      expect(controller.state.isDirty, isTrue);

      // Wait 30ms (partway through 50ms debounce)
      await Future.delayed(const Duration(milliseconds: 30));
      expect(repo.saveCount, equals(0));

      // Switch tool & select entity (UI-only state changes)
      controller.setTool(SceneEditorTool.trajectory);
      controller.select(const SceneEditorSelection.none());

      // Wait remaining 30ms. Total elapsed = 60ms (> 50ms original deadline).
      // Original autosave must NOT have been postponed!
      await Future.delayed(const Duration(milliseconds: 30));

      expect(repo.saveCount, equals(1));
      expect(controller.state.isDirty, isFalse);
    },
  );

  test('undoing back to clean state before timer fires cancels save', () async {
    controller.addBall(ballType: 'white', position: const TablePoint(0.5, 0.5));
    expect(controller.state.isDirty, isTrue);

    // Undo back to saved baseline before 50ms timer fires
    controller.undo();
    expect(controller.state.isDirty, isFalse);

    await Future.delayed(const Duration(milliseconds: 100));

    expect(repo.saveCount, equals(0));
  });

  test(
    'autosave failure exposes observable lastError and retains dirty state',
    () async {
      Object? reportedError;
      coordinator.dispose();

      coordinator = SceneEditorPersistenceCoordinator(
        repository: repo,
        controller: controller,
        debounceDuration: const Duration(milliseconds: 30),
        onError: (err, st) {
          reportedError = err;
        },
      );

      repo.shouldFailSave = true;

      controller.addBall(
        ballType: 'white',
        position: const TablePoint(0.5, 0.5),
      );
      await Future.delayed(const Duration(milliseconds: 80));

      expect(reportedError, isNotNull);
      expect(coordinator.lastError, isNotNull);
      expect(controller.state.isDirty, isTrue);
      expect(repo.saveCount, equals(0));
    },
  );

  test('dispose cancels pending autosave timer', () async {
    controller.addBall(ballType: 'white', position: const TablePoint(0.5, 0.5));
    coordinator.dispose();

    await Future.delayed(const Duration(milliseconds: 100));

    expect(repo.saveCount, equals(0));
  });

  test('flushPendingSave flushes latest state and awaits completion', () async {
    controller.addBall(ballType: 'white', position: const TablePoint(0.5, 0.5));
    expect(repo.saveCount, equals(0));

    await coordinator.flushPendingSave();

    expect(repo.saveCount, equals(1));
    expect(controller.state.isDirty, isFalse);
  });
}
