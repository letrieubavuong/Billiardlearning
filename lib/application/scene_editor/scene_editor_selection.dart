// Pure Dart Scene Editor Selection Model
// Part of Phase 4A Scene Editor Core Architecture

enum SceneEditorSelectionType {
  none,
  ball,
  trajectory,
  trajectoryPoint,
  annotation,
}

class SceneEditorSelection {
  final SceneEditorSelectionType type;
  final String? targetId;
  final int? pointIndex;

  const SceneEditorSelection._({
    required this.type,
    this.targetId,
    this.pointIndex,
  });

  const SceneEditorSelection.none()
    : type = SceneEditorSelectionType.none,
      targetId = null,
      pointIndex = null;

  const SceneEditorSelection.ball(String ballId)
    : type = SceneEditorSelectionType.ball,
      targetId = ballId,
      pointIndex = null;

  const SceneEditorSelection.trajectory(String trajectoryId)
    : type = SceneEditorSelectionType.trajectory,
      targetId = trajectoryId,
      pointIndex = null;

  const SceneEditorSelection.trajectoryPoint(
    String trajectoryId,
    int pointIndex,
  ) : type = SceneEditorSelectionType.trajectoryPoint,
      targetId = trajectoryId,
      pointIndex = pointIndex;

  const SceneEditorSelection.annotation(String annotationId)
    : type = SceneEditorSelectionType.annotation,
      targetId = annotationId,
      pointIndex = null;

  bool get isNone => type == SceneEditorSelectionType.none;
  bool get isBall => type == SceneEditorSelectionType.ball;
  bool get isTrajectory => type == SceneEditorSelectionType.trajectory;
  bool get isTrajectoryPoint =>
      type == SceneEditorSelectionType.trajectoryPoint;
  bool get isAnnotation => type == SceneEditorSelectionType.annotation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneEditorSelection &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          targetId == other.targetId &&
          pointIndex == other.pointIndex;

  @override
  int get hashCode => type.hashCode ^ targetId.hashCode ^ pointIndex.hashCode;

  @override
  String toString() {
    switch (type) {
      case SceneEditorSelectionType.none:
        return 'SceneEditorSelection.none';
      case SceneEditorSelectionType.ball:
        return 'SceneEditorSelection.ball($targetId)';
      case SceneEditorSelectionType.trajectory:
        return 'SceneEditorSelection.trajectory($targetId)';
      case SceneEditorSelectionType.trajectoryPoint:
        return 'SceneEditorSelection.trajectoryPoint($targetId, #$pointIndex)';
      case SceneEditorSelectionType.annotation:
        return 'SceneEditorSelection.annotation($targetId)';
    }
  }
}
