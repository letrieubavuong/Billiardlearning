// Pure Dart Scene Editor State Definition
// Part of Phase 4A Scene Editor Core Architecture

import '../../domain/entities/entities.dart';
import 'scene_editor_selection.dart';
import 'scene_editor_tool.dart';

class SceneEditorState {
  final BilliardScene scene;
  final SceneEditorTool activeTool;
  final SceneEditorSelection selection;
  final bool isDirty;
  final bool canUndo;
  final bool canRedo;
  final String? errorMessage;

  const SceneEditorState({
    required this.scene,
    this.activeTool = SceneEditorTool.select,
    this.selection = const SceneEditorSelection.none(),
    this.isDirty = false,
    this.canUndo = false,
    this.canRedo = false,
    this.errorMessage,
  });

  SceneEditorState copyWith({
    BilliardScene? scene,
    SceneEditorTool? activeTool,
    SceneEditorSelection? selection,
    bool? isDirty,
    bool? canUndo,
    bool? canRedo,
    String? Function()? errorMessage,
  }) {
    return SceneEditorState(
      scene: scene ?? this.scene,
      activeTool: activeTool ?? this.activeTool,
      selection: selection ?? this.selection,
      isDirty: isDirty ?? this.isDirty,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneEditorState &&
          runtimeType == other.runtimeType &&
          scene == other.scene &&
          activeTool == other.activeTool &&
          selection == other.selection &&
          isDirty == other.isDirty &&
          canUndo == other.canUndo &&
          canRedo == other.canRedo &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      scene.hashCode ^
      activeTool.hashCode ^
      selection.hashCode ^
      isDirty.hashCode ^
      canUndo.hashCode ^
      canRedo.hashCode ^
      errorMessage.hashCode;
}
