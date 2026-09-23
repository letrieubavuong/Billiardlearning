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
  bool _isSaving = false;

  SceneEditorPersistenceCoordinator({
    required this.repository,
    required this.controller,
    this.debounceDuration = defaultDebounceDuration,
    this.onError,
  }) {
    controller.addListener(_onControllerChanged);
  }

  bool get hasPendingAutosave => _debounceTimer?.isActive ?? false;

  /// Loads an existing scene by ID from repository into [controller].
  ///
  /// Throws [StateError] if the scene with [sceneId] is not found.
  Future<BilliardScene> loadScene(String sceneId) async {
    _ensureNotDisposed();
    final scene = await repository.getById(sceneId);
    if (scene == null) {
      throw StateError('Scene with ID "$sceneId" not found in repository.');
    }
    controller.loadScene(scene);
    return scene;
  }

  /// Manually saves the current scene in [controller] to repository.
  ///
  /// Calls [controller.markSaved()] ONLY after repository write succeeds.
  /// If repository write fails, editor remains dirty and error is rethrown.
  Future<void> save() async {
    _ensureNotDisposed();
    _cancelDebounce();

    if (_isSaving) return;
    _isSaving = true;

    try {
      final sceneToSave = controller.currentScene;
      await repository.save(sceneToSave);
      controller.markSaved();
    } catch (e, st) {
      if (onError != null) {
        onError!(e, st);
      }
      rethrow;
    } finally {
      _isSaving = false;
    }
  }

  /// Flushes any pending debounced save immediately if editor is dirty.
  Future<void> flushPendingSave() async {
    _ensureNotDisposed();
    if (_debounceTimer?.isActive == true || controller.state.isDirty) {
      _cancelDebounce();
      if (controller.state.isDirty) {
        await save();
      }
    }
  }

  void _onControllerChanged() {
    if (_isDisposed) return;
    if (controller.state.isDirty) {
      _scheduleDebouncedSave();
    } else {
      // If controller is clean (e.g. after undo back to saved baseline), cancel timer
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
      final sceneToSave = controller.currentScene;
      await repository.save(sceneToSave);
      if (!_isDisposed) {
        controller.markSaved();
      }
    } catch (e, st) {
      if (onError != null) {
        onError!(e, st);
      }
      // Controller remains dirty on error
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
