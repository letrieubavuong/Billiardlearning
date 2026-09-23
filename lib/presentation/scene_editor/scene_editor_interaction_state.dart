// Transient Interaction State for SceneEditor (Phase 4B)
// Manages Flutter-side drag previews and tool configurations without mutating persistent scene history.

import '../../application/scene_editor/scene_editor_selection.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

class SceneEditorInteractionState {
  final bool isDragging;
  final SceneEditorSelection? dragSelection;
  final TablePoint? initialTablePoint;
  final TablePoint? previewTablePoint;

  final String? activeTrajectoryId;
  final String selectedBallType;
  final String? selectedBallColorHex;
  final String? selectedBallLabel;

  const SceneEditorInteractionState({
    this.isDragging = false,
    this.dragSelection,
    this.initialTablePoint,
    this.previewTablePoint,
    this.activeTrajectoryId,
    this.selectedBallType = 'red',
    this.selectedBallColorHex,
    this.selectedBallLabel,
  });

  SceneEditorInteractionState copyWith({
    bool? isDragging,
    SceneEditorSelection? Function()? dragSelection,
    TablePoint? Function()? initialTablePoint,
    TablePoint? Function()? previewTablePoint,
    String? Function()? activeTrajectoryId,
    String? selectedBallType,
    String? Function()? selectedBallColorHex,
    String? Function()? selectedBallLabel,
  }) {
    return SceneEditorInteractionState(
      isDragging: isDragging ?? this.isDragging,
      dragSelection: dragSelection != null
          ? dragSelection()
          : this.dragSelection,
      initialTablePoint: initialTablePoint != null
          ? initialTablePoint()
          : this.initialTablePoint,
      previewTablePoint: previewTablePoint != null
          ? previewTablePoint()
          : this.previewTablePoint,
      activeTrajectoryId: activeTrajectoryId != null
          ? activeTrajectoryId()
          : this.activeTrajectoryId,
      selectedBallType: selectedBallType ?? this.selectedBallType,
      selectedBallColorHex: selectedBallColorHex != null
          ? selectedBallColorHex()
          : this.selectedBallColorHex,
      selectedBallLabel: selectedBallLabel != null
          ? selectedBallLabel()
          : this.selectedBallLabel,
    );
  }

  /// Derives an ephemeral [BilliardScene] for transient rendering preview during drag gestures.
  ///
  /// Does NOT mutate persistent history, repository, or dirty baseline.
  BilliardScene getPreviewScene(BilliardScene canonicalScene) {
    if (!isDragging || dragSelection == null || previewTablePoint == null) {
      return canonicalScene;
    }

    final sel = dragSelection!;
    final previewPt = previewTablePoint!;

    switch (sel.type) {
      case SceneEditorSelectionType.ball:
        final idx = canonicalScene.balls.indexWhere(
          (b) => b.id == sel.targetId,
        );
        if (idx == -1) return canonicalScene;

        final existing = canonicalScene.balls[idx];
        final updated = BallPosition(
          id: existing.id,
          ballType: existing.ballType,
          position: previewPt,
          label: existing.label,
          colorHex: existing.colorHex,
          rotation: existing.rotation,
          legacyType: existing.legacyType,
        );
        final newBalls = List<BallPosition>.from(canonicalScene.balls);
        newBalls[idx] = updated;
        return canonicalScene.copyWith(balls: newBalls);

      case SceneEditorSelectionType.annotation:
        final idx = canonicalScene.annotations.indexWhere(
          (a) => a.id == sel.targetId,
        );
        if (idx == -1) return canonicalScene;

        final existing = canonicalScene.annotations[idx];
        final updated = SceneAnnotation(
          id: existing.id,
          text: existing.text,
          position: previewPt,
          colorHex: existing.colorHex,
          rotation: existing.rotation,
          role: existing.role,
          cushionSide: existing.cushionSide,
        );
        final newAnns = List<SceneAnnotation>.from(canonicalScene.annotations);
        newAnns[idx] = updated;
        return canonicalScene.copyWith(annotations: newAnns);

      case SceneEditorSelectionType.trajectoryPoint:
        final idx = canonicalScene.trajectories.indexWhere(
          (t) => t.id == sel.targetId,
        );
        if (idx == -1) return canonicalScene;

        final existing = canonicalScene.trajectories[idx];
        final ptIdx = sel.pointIndex;
        if (ptIdx == null || ptIdx < 0 || ptIdx >= existing.points.length) {
          return canonicalScene;
        }

        final newPts = List<TablePoint>.from(existing.points);
        newPts[ptIdx] = previewPt;

        final updated = TrajectoryLine(
          id: existing.id,
          colorHex: existing.colorHex,
          points: newPts,
        );
        final newTrajs = List<TrajectoryLine>.from(canonicalScene.trajectories);
        newTrajs[idx] = updated;
        return canonicalScene.copyWith(trajectories: newTrajs);

      case SceneEditorSelectionType.trajectory:
      case SceneEditorSelectionType.none:
        return canonicalScene;
    }
  }
}
