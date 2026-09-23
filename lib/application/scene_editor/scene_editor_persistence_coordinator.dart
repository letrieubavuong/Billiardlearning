// Pure Dart Persistence Coordinator for Scene Editor
// Connects SceneEditorController to VNextSceneRepository with Debounced Autosave

import 'dart:async';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import 'scene_editor_controller.dart';

typedef SceneEditorSaveErrorHandler =
    void Function(Object error, StackTrace stackTrace);

/// Pure Dart coordinator linking [SceneEditorController] with [VNextSceneRepository].
class SceneEditorPersistenceCoordinator {
  static const Duration defaultDebounceDuration = Duration(milliseconds: 750);

  final VNextSceneRepository repository;
  final SceneEditorController controller;
  final Duration debounceDuration;
  final SceneEditorSaveErrorHandler? onError;

  Timer? _debounceTimer;
  bool _isDisposed = false;
  Future<void>? _activeSaveFuture;

  BilliardScene? _lastObservedScene;
  Object? _lastError;

  int _sessionToken = 0;
  int _activeSaveCount = 0;
  int _peakSaveCount = 0;

  SceneEditorPersistenceCoordinator({
    required this.repository,
    required this.controller,
    this.debounceDuration = defaultDebounceDuration,
    this.onError,
  }) {
    _lastObservedScene = controller.currentScene;
    controller.addListener(_onControllerChanged);
  }

  bool get hasPendingAutosave => _debounceTimer?.isActive ?? false;
  Object? get lastError => _lastError;
  int get activeSaveCount => _activeSaveCount;
  int get maxConcurrentSaves => _peakSaveCount;

  /// Loads an existing scene by ID from repository into [controller].
  ///
  /// Throws [StateError] if the scene with [sceneId] is not found.
  Future<BilliardScene> loadScene(String sceneId) async {
    _ensureNotDisposed();
    _cancelDebounce();
    _sessionToken++;

    final scene = await repository.getById(sceneId);
    if (scene == null) {
      throw StateError('Scene with ID "$sceneId" not found in repository.');
    }
    controller.loadScene(scene);
    _lastObservedScene = controller.currentScene;
    _lastError = null;
    return scene;
  }

  /// Manually saves the current scene snapshot to repository.
  ///
  /// Guarantees serialized execution and updates baseline to the persisted snapshot.
  /// If user edits during save, editor remains dirty and follow-up save persists latest state.
  Future<void> save() async {
    _ensureNotDisposed();
    _cancelDebounce();
    await _executeSerializedSavePipeline(rethrowErrors: true);
  }

  /// Flushes any pending debounced save immediately and persists latest dirty state.
  Future<void> flushPendingSave() async {
    _ensureNotDisposed();
    _cancelDebounce();
    while (!_isDisposed && controller.state.isDirty) {
      final sceneBefore = controller.currentScene;
      await _executeSerializedSavePipeline(rethrowErrors: true);
      // If controller scene did not change during save, break loop
      if (SceneEditorController.areScenesIdentical(
        controller.currentScene,
        sceneBefore,
      )) {
        break;
      }
    }
  }

  void _onControllerChanged() {
    if (_isDisposed) return;
    final currentScene = controller.currentScene;

    // Content-Only Trigger: Ignore notifications where canonical scene content did not change
    if (_lastObservedScene != null &&
        SceneEditorController.areScenesIdentical(
          currentScene,
          _lastObservedScene!,
        )) {
      return;
    }

    _lastObservedScene = currentScene;

    if (controller.state.isDirty) {
      _scheduleDebouncedSave();
    } else {
      _cancelDebounce();
    }
  }

  void _scheduleDebouncedSave() {
    _cancelDebounce();
    _debounceTimer = Timer(debounceDuration, _performAutosave);
  }

  void _cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<void> _performAutosave() async {
    if (_isDisposed) return;
    if (!controller.state.isDirty) return;

    try {
      await _executeSerializedSavePipeline(rethrowErrors: false);
    } catch (e, st) {
      _lastError = e;
      if (onError != null) {
        onError!(e, st);
      }
    }
  }

  /// Core serialized save pipeline ensuring maximum 1 concurrent repository.save write.
  Future<void> _executeSerializedSavePipeline({
    required bool rethrowErrors,
  }) async {
    while (_activeSaveFuture != null) {
      await _activeSaveFuture;
      if (_isDisposed) return;
    }

    if (!controller.state.isDirty) return;

    final completer = Completer<void>();
    _activeSaveFuture = completer.future;

    _activeSaveCount++;
    if (_activeSaveCount > _peakSaveCount) {
      _peakSaveCount = _activeSaveCount;
    }

    final snapshotToSave = controller.currentScene;
    final sessionToken = _sessionToken;
    var saveSucceeded = false;

    try {
      await repository.save(snapshotToSave);
      saveSucceeded = true;
      _lastError = null;

      // Session Guard & Snapshot-Aware Baseline Update
      if (!_isDisposed && _sessionToken == sessionToken) {
        controller.markPersistedSnapshot(snapshotToSave);
      }
    } catch (e, st) {
      _lastError = e;
      if (onError != null) {
        onError!(e, st);
      }
      if (rethrowErrors) {
        rethrow;
      }
    } finally {
      _activeSaveCount--;
      completer.complete();
      _activeSaveFuture = null;

      // Follow-up autosave is scheduled ONLY IF:
      // 1. Write succeeded (saveSucceeded == true)
      // 2. We are in autosave mode (!rethrowErrors)
      // 3. Same session token active (_sessionToken == sessionToken)
      // 4. Current controller scene differs from snapshotToSave (i.e. user edited C while saving B)
      if (!_isDisposed &&
          !rethrowErrors &&
          saveSucceeded &&
          _sessionToken == sessionToken &&
          controller.state.isDirty &&
          !SceneEditorController.areScenesIdentical(
            controller.currentScene,
            snapshotToSave,
          )) {
        _scheduleDebouncedSave();
      }
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _cancelDebounce();
    controller.removeListener(_onControllerChanged);
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'Cannot use SceneEditorPersistenceCoordinator after dispose.',
      );
    }
  }
}
