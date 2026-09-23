// Pure Dart Scene Editor History Stack
// Part of Phase 4A Scene Editor Core Architecture

import '../../domain/entities/entities.dart';

class SceneEditorHistory {
  final int maxHistory;
  final List<BilliardScene> _undoStack = [];
  final List<BilliardScene> _redoStack = [];

  SceneEditorHistory({this.maxHistory = 100}) {
    if (maxHistory <= 0) {
      throw ArgumentError('maxHistory must be positive');
    }
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  /// Pushes [scene] onto the undo stack and clears the redo stack.
  void push(BilliardScene scene) {
    _undoStack.add(scene);
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  /// Undoes from history.
  ///
  /// Pushes [currentScene] onto the redo stack and returns the most recent undo snapshot.
  BilliardScene? undo(BilliardScene currentScene) {
    if (!canUndo) return null;
    _redoStack.add(currentScene);
    return _undoStack.removeLast();
  }

  /// Redoes from history.
  ///
  /// Pushes [currentScene] onto the undo stack and returns the most recent redo snapshot.
  BilliardScene? redo(BilliardScene currentScene) {
    if (!canRedo) return null;
    _undoStack.add(currentScene);
    return _redoStack.removeLast();
  }

  /// Clears undo and redo stacks.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
