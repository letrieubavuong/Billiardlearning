// Pure Dart Scene Editor Controller Facade
// Part of Phase 4A Scene Editor Core Architecture

import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import 'scene_editor_history.dart';
import 'scene_editor_selection.dart';
import 'scene_editor_state.dart';
import 'scene_editor_tool.dart';

class SceneEditorController {
  final DateTime Function() _clock;
  final SceneEditorHistory _history;

  SceneEditorState _state;
  BilliardScene _savedBaseline;

  SceneEditorController({
    BilliardScene? initialScene,
    SceneEditorTool activeTool = SceneEditorTool.select,
    DateTime Function()? clock,
    int maxHistory = 100,
  })  : _clock = clock ?? DateTime.now,
        _history = SceneEditorHistory(maxHistory: maxHistory),
        _savedBaseline = initialScene ?? _createDefaultInitialScene(clock ?? DateTime.now),
        _state = SceneEditorState(
          scene: initialScene ?? _createDefaultInitialScene(clock ?? DateTime.now),
          activeTool: activeTool,
          selection: const SceneEditorSelection.none(),
          isDirty: false,
          canUndo: false,
          canRedo: false,
        );

  static BilliardScene _createDefaultInitialScene(DateTime Function() clock) {
    final now = clock().toUtc();
    return BilliardScene(
      id: StableId.generate(),
      name: 'Mặt bàn mới',
      tableConfig: const TableConfig(),
      balls: const [],
      trajectories: const [],
      annotations: const [],
      cueInstruction: null,
      presentationConfig: const ScenePresentationConfig(),
      source: SceneSource.manual,
      status: SceneStatus.active,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
  }

  SceneEditorState get state => _state;
  BilliardScene get currentScene => _state.scene;

  /// Helper to clamp TablePoint to normalized valid range [0, 1] x [0, 1].
  TablePoint _clampTablePoint(TablePoint point) {
    final u = point.u.clamp(0.0, 1.0);
    final v = point.v.clamp(0.0, 1.0);
    return TablePoint(u, v);
  }

  /// Sets active tool. Tool switching does not create undo history.
  void setTool(SceneEditorTool tool) {
    if (_state.activeTool == tool) return;
    _state = _state.copyWith(activeTool: tool);
  }

  /// Sets selection. Selection changes do not create undo history.
  void select(SceneEditorSelection selection) {
    if (_state.selection == selection) return;
    _state = _state.copyWith(selection: selection);
  }

  /// Clears active selection.
  void clearSelection() {
    select(const SceneEditorSelection.none());
  }

  /// Commits a new scene snapshot, updating history and dirty state.
  void _commitSceneEdit(BilliardScene newScene, {SceneEditorSelection? newSelection}) {
    if (newScene == _state.scene) return; // No-op edit check

    _history.push(_state.scene);
    final now = _clock().toUtc();
    final updatedScene = newScene.copyWith(updatedAt: now);

    final isDirty = updatedScene != _savedBaseline;

    _state = _state.copyWith(
      scene: updatedScene,
      selection: newSelection ?? _state.selection,
      isDirty: isDirty,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
      errorMessage: () => null,
    );
  }

  // --- BALL OPERATIONS ---

  void addBall({
    required String ballType,
    required TablePoint position,
    String? label,
    String? colorHex,
    double? rotation,
    int? legacyType,
  }) {
    final clampedPos = _clampTablePoint(position);
    final newBallId = StableId.generate();
    final newBall = BallPosition(
      id: newBallId,
      ballType: ballType,
      position: clampedPos,
      label: label,
      colorHex: colorHex,
      rotation: rotation,
      legacyType: legacyType,
    );

    final newBalls = List<BallPosition>.from(_state.scene.balls)..add(newBall);
    final newScene = _state.scene.copyWith(balls: newBalls);

    _commitSceneEdit(
      newScene,
      newSelection: SceneEditorSelection.ball(newBallId),
    );
  }

  void moveBall(String ballId, TablePoint newPosition) {
    final clampedPos = _clampTablePoint(newPosition);
    final index = _state.scene.balls.indexWhere((b) => b.id == ballId);
    if (index == -1) {
      throw ArgumentError('Ball with id $ballId not found');
    }

    final existing = _state.scene.balls[index];
    if (existing.position == clampedPos) return; // No-op check

    final updated = BallPosition(
      id: existing.id,
      ballType: existing.ballType,
      position: clampedPos,
      label: existing.label,
      colorHex: existing.colorHex,
      rotation: existing.rotation,
      legacyType: existing.legacyType,
    );

    final newBalls = List<BallPosition>.from(_state.scene.balls);
    newBalls[index] = updated;

    _commitSceneEdit(
      _state.scene.copyWith(balls: newBalls),
      newSelection: SceneEditorSelection.ball(ballId),
    );
  }

  void updateBall(BallPosition updatedBall) {
    final index = _state.scene.balls.indexWhere((b) => b.id == updatedBall.id);
    if (index == -1) {
      throw ArgumentError('Ball with id ${updatedBall.id} not found');
    }

    final clampedBall = BallPosition(
      id: updatedBall.id,
      ballType: updatedBall.ballType,
      position: _clampTablePoint(updatedBall.position),
      label: updatedBall.label,
      colorHex: updatedBall.colorHex,
      rotation: updatedBall.rotation,
      legacyType: updatedBall.legacyType,
    );

    if (_state.scene.balls[index] == clampedBall) return; // No-op check

    final newBalls = List<BallPosition>.from(_state.scene.balls);
    newBalls[index] = clampedBall;

    _commitSceneEdit(_state.scene.copyWith(balls: newBalls));
  }

  void deleteBall(String ballId) {
    final index = _state.scene.balls.indexWhere((b) => b.id == ballId);
    if (index == -1) return;

    final newBalls = List<BallPosition>.from(_state.scene.balls)..removeAt(index);
    final newSelection = _state.selection.targetId == ballId
        ? const SceneEditorSelection.none()
        : _state.selection;

    _commitSceneEdit(
      _state.scene.copyWith(balls: newBalls),
      newSelection: newSelection,
    );
  }

  // --- TRAJECTORY OPERATIONS ---

  void addTrajectory({
    String colorHex = '#FFFFFF',
    List<TablePoint> points = const [],
  }) {
    final clampedPoints = points.map(_clampTablePoint).toList();
    final trajId = StableId.generate();
    final traj = TrajectoryLine(
      id: trajId,
      colorHex: colorHex,
      points: clampedPoints,
    );

    final newTrajs = List<TrajectoryLine>.from(_state.scene.trajectories)..add(traj);
    _commitSceneEdit(
      _state.scene.copyWith(trajectories: newTrajs),
      newSelection: SceneEditorSelection.trajectory(trajId),
    );
  }

  void addTrajectoryPoint(String trajectoryId, TablePoint point) {
    final index = _state.scene.trajectories.indexWhere((t) => t.id == trajectoryId);
    if (index == -1) {
      throw ArgumentError('Trajectory with id $trajectoryId not found');
    }

    final existing = _state.scene.trajectories[index];
    final clampedPt = _clampTablePoint(point);
    final newPoints = List<TablePoint>.from(existing.points)..add(clampedPt);

    final updated = TrajectoryLine(
      id: existing.id,
      colorHex: existing.colorHex,
      points: newPoints,
    );

    final newTrajs = List<TrajectoryLine>.from(_state.scene.trajectories);
    newTrajs[index] = updated;

    _commitSceneEdit(
      _state.scene.copyWith(trajectories: newTrajs),
      newSelection: SceneEditorSelection.trajectoryPoint(trajectoryId, newPoints.length - 1),
    );
  }

  void moveTrajectoryPoint(String trajectoryId, int pointIndex, TablePoint newPoint) {
    final index = _state.scene.trajectories.indexWhere((t) => t.id == trajectoryId);
    if (index == -1) {
      throw ArgumentError('Trajectory with id $trajectoryId not found');
    }

    final existing = _state.scene.trajectories[index];
    if (pointIndex < 0 || pointIndex >= existing.points.length) {
      throw RangeError.range(pointIndex, 0, existing.points.length - 1, 'pointIndex');
    }

    final clampedPt = _clampTablePoint(newPoint);
    if (existing.points[pointIndex] == clampedPt) return; // No-op check

    final newPoints = List<TablePoint>.from(existing.points);
    newPoints[pointIndex] = clampedPt;

    final updated = TrajectoryLine(
      id: existing.id,
      colorHex: existing.colorHex,
      points: newPoints,
    );

    final newTrajs = List<TrajectoryLine>.from(_state.scene.trajectories);
    newTrajs[index] = updated;

    _commitSceneEdit(
      _state.scene.copyWith(trajectories: newTrajs),
      newSelection: SceneEditorSelection.trajectoryPoint(trajectoryId, pointIndex),
    );
  }

  void removeTrajectoryPoint(String trajectoryId, int pointIndex) {
    final index = _state.scene.trajectories.indexWhere((t) => t.id == trajectoryId);
    if (index == -1) return;

    final existing = _state.scene.trajectories[index];
    if (pointIndex < 0 || pointIndex >= existing.points.length) return;

    final newPoints = List<TablePoint>.from(existing.points)..removeAt(pointIndex);
    final updated = TrajectoryLine(
      id: existing.id,
      colorHex: existing.colorHex,
      points: newPoints,
    );

    final newTrajs = List<TrajectoryLine>.from(_state.scene.trajectories);
    newTrajs[index] = updated;

    _commitSceneEdit(_state.scene.copyWith(trajectories: newTrajs));
  }

  void changeTrajectoryColorHex(String trajectoryId, String colorHex) {
    final index = _state.scene.trajectories.indexWhere((t) => t.id == trajectoryId);
    if (index == -1) return;

    final existing = _state.scene.trajectories[index];
    if (existing.colorHex == colorHex) return; // No-op check

    final updated = TrajectoryLine(
      id: existing.id,
      colorHex: colorHex,
      points: existing.points,
    );

    final newTrajs = List<TrajectoryLine>.from(_state.scene.trajectories);
    newTrajs[index] = updated;

    _commitSceneEdit(_state.scene.copyWith(trajectories: newTrajs));
  }

  void deleteTrajectory(String trajectoryId) {
    final index = _state.scene.trajectories.indexWhere((t) => t.id == trajectoryId);
    if (index == -1) return;

    final newTrajs = List<TrajectoryLine>.from(_state.scene.trajectories)..removeAt(index);
    final newSelection = _state.selection.targetId == trajectoryId
        ? const SceneEditorSelection.none()
        : _state.selection;

    _commitSceneEdit(
      _state.scene.copyWith(trajectories: newTrajs),
      newSelection: newSelection,
    );
  }

  // --- ANNOTATION OPERATIONS ---

  void addAnnotation({
    required String text,
    required TablePoint position,
    String? colorHex,
    double? rotation,
    String? role,
    String? cushionSide,
  }) {
    final clampedPos = _clampTablePoint(position);
    final annId = StableId.generate();
    final annotation = SceneAnnotation(
      id: annId,
      text: text,
      position: clampedPos,
      colorHex: colorHex,
      rotation: rotation,
      role: role,
      cushionSide: cushionSide,
    );

    final newAnns = List<SceneAnnotation>.from(_state.scene.annotations)..add(annotation);
    _commitSceneEdit(
      _state.scene.copyWith(annotations: newAnns),
      newSelection: SceneEditorSelection.annotation(annId),
    );
  }

  void moveAnnotation(String annotationId, TablePoint newPosition) {
    final clampedPos = _clampTablePoint(newPosition);
    final index = _state.scene.annotations.indexWhere((a) => a.id == annotationId);
    if (index == -1) {
      throw ArgumentError('Annotation with id $annotationId not found');
    }

    final existing = _state.scene.annotations[index];
    if (existing.position == clampedPos) return; // No-op check

    final updated = SceneAnnotation(
      id: existing.id,
      text: existing.text,
      position: clampedPos,
      colorHex: existing.colorHex,
      rotation: existing.rotation,
      role: existing.role,
      cushionSide: existing.cushionSide,
    );

    final newAnns = List<SceneAnnotation>.from(_state.scene.annotations);
    newAnns[index] = updated;

    _commitSceneEdit(
      _state.scene.copyWith(annotations: newAnns),
      newSelection: SceneEditorSelection.annotation(annotationId),
    );
  }

  void editAnnotationText(String annotationId, String text) {
    final index = _state.scene.annotations.indexWhere((a) => a.id == annotationId);
    if (index == -1) return;

    final existing = _state.scene.annotations[index];
    if (existing.text == text) return; // No-op check

    final updated = SceneAnnotation(
      id: existing.id,
      text: text,
      position: existing.position,
      colorHex: existing.colorHex,
      rotation: existing.rotation,
      role: existing.role,
      cushionSide: existing.cushionSide,
    );

    final newAnns = List<SceneAnnotation>.from(_state.scene.annotations);
    newAnns[index] = updated;

    _commitSceneEdit(_state.scene.copyWith(annotations: newAnns));
  }

  void editAnnotationRotation(String annotationId, double rotationDegrees) {
    final index = _state.scene.annotations.indexWhere((a) => a.id == annotationId);
    if (index == -1) return;

    final existing = _state.scene.annotations[index];
    if (existing.rotation == rotationDegrees) return; // No-op check

    final updated = SceneAnnotation(
      id: existing.id,
      text: existing.text,
      position: existing.position,
      colorHex: existing.colorHex,
      rotation: rotationDegrees,
      role: existing.role,
      cushionSide: existing.cushionSide,
    );

    final newAnns = List<SceneAnnotation>.from(_state.scene.annotations);
    newAnns[index] = updated;

    _commitSceneEdit(_state.scene.copyWith(annotations: newAnns));
  }

  void editAnnotationColor(String annotationId, String colorHex) {
    final index = _state.scene.annotations.indexWhere((a) => a.id == annotationId);
    if (index == -1) return;

    final existing = _state.scene.annotations[index];
    if (existing.colorHex == colorHex) return; // No-op check

    final updated = SceneAnnotation(
      id: existing.id,
      text: existing.text,
      position: existing.position,
      colorHex: colorHex,
      rotation: existing.rotation,
      role: existing.role,
      cushionSide: existing.cushionSide,
    );

    final newAnns = List<SceneAnnotation>.from(_state.scene.annotations);
    newAnns[index] = updated;

    _commitSceneEdit(_state.scene.copyWith(annotations: newAnns));
  }

  void deleteAnnotation(String annotationId) {
    final index = _state.scene.annotations.indexWhere((a) => a.id == annotationId);
    if (index == -1) return;

    final newAnns = List<SceneAnnotation>.from(_state.scene.annotations)..removeAt(index);
    final newSelection = _state.selection.targetId == annotationId
        ? const SceneEditorSelection.none()
        : _state.selection;

    _commitSceneEdit(
      _state.scene.copyWith(annotations: newAnns),
      newSelection: newSelection,
    );
  }

  // --- PRESENTATION CONFIG OPERATIONS ---

  void updatePresentationConfig({
    int? legacySystemIndex,
    int? legacyViewTypeIndex,
    double? labelFontSize,
  }) {
    final currentConfig = _state.scene.presentationConfig ?? const ScenePresentationConfig();
    final updatedConfig = ScenePresentationConfig(
      legacySystemIndex: legacySystemIndex ?? currentConfig.legacySystemIndex,
      legacyViewTypeIndex: legacyViewTypeIndex ?? currentConfig.legacyViewTypeIndex,
      labelFontSize: labelFontSize ?? currentConfig.labelFontSize,
    );

    if (currentConfig == updatedConfig) return; // No-op check

    _commitSceneEdit(_state.scene.copyWith(presentationConfig: updatedConfig));
  }

  // --- HISTORY & BASELINE MANAGEMENT ---

  void undo() {
    if (!_history.canUndo) return;

    final previousScene = _history.undo(_state.scene);
    if (previousScene == null) return;

    final isDirty = previousScene != _savedBaseline;

    _state = _state.copyWith(
      scene: previousScene,
      isDirty: isDirty,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
      errorMessage: () => null,
    );
  }

  void redo() {
    if (!_history.canRedo) return;

    final nextScene = _history.redo(_state.scene);
    if (nextScene == null) return;

    final isDirty = nextScene != _savedBaseline;

    _state = _state.copyWith(
      scene: nextScene,
      isDirty: isDirty,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
      errorMessage: () => null,
    );
  }

  /// Sets the current scene state as the saved baseline (`isDirty = false`).
  void markSaved() {
    _savedBaseline = _state.scene;
    _state = _state.copyWith(isDirty: false);
  }

  /// Loads [scene] as a new editor session baseline.
  void loadScene(BilliardScene scene) {
    _history.clear();
    _savedBaseline = scene;
    _state = SceneEditorState(
      scene: scene,
      activeTool: _state.activeTool,
      selection: const SceneEditorSelection.none(),
      isDirty: false,
      canUndo: false,
      canRedo: false,
    );
  }
}
