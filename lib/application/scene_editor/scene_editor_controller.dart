// Pure Dart Scene Editor Controller Facade
// Part of Phase 4A Scene Editor Core Architecture

import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import 'scene_editor_exception.dart';
import 'scene_editor_history.dart';
import 'scene_editor_selection.dart';
import 'scene_editor_state.dart';
import 'scene_editor_tool.dart';

typedef SceneEditorListener = void Function();

class SceneEditorController {
  final DateTime Function() _clock;
  final SceneEditorHistory _history;
  final List<SceneEditorListener> _listeners = [];

  SceneEditorState _state;
  BilliardScene _savedBaseline;

  void addListener(SceneEditorListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(SceneEditorListener listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in List<SceneEditorListener>.from(_listeners)) {
      listener();
    }
  }

  SceneEditorController._({
    required BilliardScene initialScene,
    required SceneEditorTool activeTool,
    required DateTime Function() clock,
    required int maxHistory,
  }) : _clock = clock,
       _history = SceneEditorHistory(maxHistory: maxHistory),
       _savedBaseline = initialScene,
       _state = SceneEditorState(
         scene: initialScene,
         activeTool: activeTool,
         selection: const SceneEditorSelection.none(),
         isDirty: false,
         canUndo: false,
         canRedo: false,
       );

  factory SceneEditorController({
    BilliardScene? initialScene,
    SceneEditorTool activeTool = SceneEditorTool.select,
    DateTime Function()? clock,
    int maxHistory = 100,
  }) {
    final effectiveClock = clock ?? DateTime.now;
    final effectiveScene = _freezeScene(
      initialScene ?? _createDefaultInitialScene(effectiveClock),
    );

    return SceneEditorController._(
      initialScene: effectiveScene,
      activeTool: activeTool,
      clock: effectiveClock,
      maxHistory: maxHistory,
    );
  }

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

  static dynamic _freezeJson(dynamic value) {
    if (value is Map) {
      final frozenMap = <String, dynamic>{};
      value.forEach((k, v) {
        frozenMap[k.toString()] = _freezeJson(v);
      });
      return Map<String, dynamic>.unmodifiable(frozenMap);
    } else if (value is List) {
      final frozenList = value.map(_freezeJson).toList();
      return List<dynamic>.unmodifiable(frozenList);
    }
    return value;
  }

  static BilliardScene _freezeScene(BilliardScene scene) {
    final frozenTimeline = scene.teachingTimeline != null
        ? _freezeJson(scene.teachingTimeline) as Map<String, dynamic>
        : null;

    return scene.copyWith(
      balls: List<BallPosition>.unmodifiable(scene.balls),
      trajectories: List<TrajectoryLine>.unmodifiable(
        scene.trajectories.map(
          (t) => TrajectoryLine(
            id: t.id,
            colorHex: t.colorHex,
            points: List<TablePoint>.unmodifiable(t.points),
          ),
        ),
      ),
      annotations: List<SceneAnnotation>.unmodifiable(scene.annotations),
      teachingTimeline: frozenTimeline,
    );
  }

  static bool _areJsonValuesIdentical(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_areJsonValuesIdentical(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_areJsonValuesIdentical(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  static bool _areBallsIdentical(BallPosition a, BallPosition b) {
    return a.id == b.id &&
        a.ballType == b.ballType &&
        a.position == b.position &&
        a.label == b.label &&
        a.colorHex == b.colorHex &&
        a.rotation == b.rotation &&
        a.legacyType == b.legacyType;
  }

  static bool _areTrajectoriesIdentical(TrajectoryLine a, TrajectoryLine b) {
    if (a.id != b.id || a.colorHex != b.colorHex) return false;
    if (a.points.length != b.points.length) return false;
    for (var i = 0; i < a.points.length; i++) {
      if (a.points[i] != b.points[i]) return false;
    }
    return true;
  }

  static bool _areAnnotationsIdentical(SceneAnnotation a, SceneAnnotation b) {
    return a.id == b.id &&
        a.text == b.text &&
        a.position == b.position &&
        a.colorHex == b.colorHex &&
        a.rotation == b.rotation &&
        a.role == b.role &&
        a.cushionSide == b.cushionSide;
  }

  static bool _areScenesIdentical(BilliardScene a, BilliardScene b) {
    if (a.id != b.id ||
        a.name != b.name ||
        a.source != b.source ||
        a.status != b.status ||
        a.version != b.version ||
        a.tableConfig.type != b.tableConfig.type ||
        a.tableConfig.widthMeters != b.tableConfig.widthMeters ||
        a.tableConfig.lengthMeters != b.tableConfig.lengthMeters ||
        a.presentationConfig != b.presentationConfig) {
      return false;
    }
    if (!_areJsonValuesIdentical(a.teachingTimeline, b.teachingTimeline)) {
      return false;
    }
    if (a.balls.length != b.balls.length) return false;
    for (var i = 0; i < a.balls.length; i++) {
      if (!_areBallsIdentical(a.balls[i], b.balls[i])) return false;
    }
    if (a.trajectories.length != b.trajectories.length) return false;
    for (var i = 0; i < a.trajectories.length; i++) {
      if (!_areTrajectoriesIdentical(a.trajectories[i], b.trajectories[i])) {
        return false;
      }
    }
    if (a.annotations.length != b.annotations.length) return false;
    for (var i = 0; i < a.annotations.length; i++) {
      if (!_areAnnotationsIdentical(a.annotations[i], b.annotations[i])) {
        return false;
      }
    }
    return true;
  }

  static SceneEditorSelection sanitizeSelection(
    BilliardScene scene,
    SceneEditorSelection selection, {
    bool isHistoryNavigation = false,
  }) {
    switch (selection.type) {
      case SceneEditorSelectionType.none:
        return const SceneEditorSelection.none();
      case SceneEditorSelectionType.ball:
        final exists = scene.balls.any((b) => b.id == selection.targetId);
        return exists ? selection : const SceneEditorSelection.none();
      case SceneEditorSelectionType.trajectory:
        final exists = scene.trajectories.any(
          (t) => t.id == selection.targetId,
        );
        return exists ? selection : const SceneEditorSelection.none();
      case SceneEditorSelectionType.trajectoryPoint:
        if (isHistoryNavigation) return const SceneEditorSelection.none();
        final index = scene.trajectories.indexWhere(
          (t) => t.id == selection.targetId,
        );
        if (index == -1) return const SceneEditorSelection.none();
        final traj = scene.trajectories[index];
        if (selection.pointIndex == null ||
            selection.pointIndex! < 0 ||
            selection.pointIndex! >= traj.points.length) {
          return const SceneEditorSelection.none();
        }
        return selection;
      case SceneEditorSelectionType.annotation:
        final exists = scene.annotations.any((a) => a.id == selection.targetId);
        return exists ? selection : const SceneEditorSelection.none();
    }
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
    _notifyListeners();
  }

  /// Sets selection. Selection changes do not create undo history.
  void select(SceneEditorSelection selection) {
    final sanitized = sanitizeSelection(_state.scene, selection);
    if (_state.selection == sanitized) return;
    _state = _state.copyWith(selection: sanitized);
    _notifyListeners();
  }

  /// Clears active selection.
  void clearSelection() {
    select(const SceneEditorSelection.none());
  }

  /// Commits a new scene snapshot, updating history and dirty state.
  void _commitSceneEdit(
    BilliardScene newScene, {
    SceneEditorSelection? newSelection,
  }) {
    final frozenNewScene = _freezeScene(newScene);
    if (_areScenesIdentical(frozenNewScene, _state.scene))
      return; // No-op edit check

    _history.push(_state.scene);
    final now = _clock().toUtc();
    final updatedScene = _freezeScene(frozenNewScene.copyWith(updatedAt: now));

    final isDirty = !_areScenesIdentical(updatedScene, _savedBaseline);
    final sanitizedSel = sanitizeSelection(
      updatedScene,
      newSelection ?? _state.selection,
    );

    _state = _state.copyWith(
      scene: updatedScene,
      selection: sanitizedSel,
      isDirty: isDirty,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
      errorMessage: () => null,
    );
    _notifyListeners();
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
      throw SceneEditorTargetNotFoundException(
        'Ball with id $ballId not found',
      );
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
      throw SceneEditorTargetNotFoundException(
        'Ball with id ${updatedBall.id} not found',
      );
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

    final existing = _state.scene.balls[index];
    if (_areBallsIdentical(existing, clampedBall)) return; // No-op check

    final newBalls = List<BallPosition>.from(_state.scene.balls);
    newBalls[index] = clampedBall;

    _commitSceneEdit(_state.scene.copyWith(balls: newBalls));
  }

  void deleteBall(String ballId) {
    final index = _state.scene.balls.indexWhere((b) => b.id == ballId);
    if (index == -1) {
      throw SceneEditorTargetNotFoundException(
        'Ball with id $ballId not found',
      );
    }

    final newBalls = List<BallPosition>.from(_state.scene.balls)
      ..removeAt(index);
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

    final newTrajs = List<TrajectoryLine>.from(_state.scene.trajectories)
      ..add(traj);
    _commitSceneEdit(
      _state.scene.copyWith(trajectories: newTrajs),
      newSelection: SceneEditorSelection.trajectory(trajId),
    );
  }

  void addTrajectoryPoint(String trajectoryId, TablePoint point) {
    final index = _state.scene.trajectories.indexWhere(
      (t) => t.id == trajectoryId,
    );
    if (index == -1) {
      throw SceneEditorTargetNotFoundException(
        'Trajectory with id $trajectoryId not found',
      );
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
      newSelection: SceneEditorSelection.trajectoryPoint(
        trajectoryId,
        newPoints.length - 1,
      ),
    );
  }

  void moveTrajectoryPoint(
    String trajectoryId,
    int pointIndex,
    TablePoint newPoint,
  ) {
    final index = _state.scene.trajectories.indexWhere(
      (t) => t.id == trajectoryId,
    );
    if (index == -1) {
      throw SceneEditorTargetNotFoundException(
        'Trajectory with id $trajectoryId not found',
      );
    }

    final existing = _state.scene.trajectories[index];
    if (pointIndex < 0 || pointIndex >= existing.points.length) {
      throw SceneEditorInvalidOperationException(
        'Trajectory point index $pointIndex out of range',
      );
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
      newSelection: SceneEditorSelection.trajectoryPoint(
        trajectoryId,
        pointIndex,
      ),
    );
  }

  void removeTrajectoryPoint(String trajectoryId, int pointIndex) {
    final index = _state.scene.trajectories.indexWhere(
      (t) => t.id == trajectoryId,
    );
    if (index == -1) {
      throw SceneEditorTargetNotFoundException(
        'Trajectory with id $trajectoryId not found',
      );
    }

    final existing = _state.scene.trajectories[index];
    if (pointIndex < 0 || pointIndex >= existing.points.length) {
      throw SceneEditorInvalidOperationException(
        'Trajectory point index $pointIndex out of range',
      );
    }

    final newPoints = List<TablePoint>.from(existing.points)
      ..removeAt(pointIndex);
    final updated = TrajectoryLine(
      id: existing.id,
      colorHex: existing.colorHex,
      points: newPoints,
    );

    final newTrajs = List<TrajectoryLine>.from(_state.scene.trajectories);
    newTrajs[index] = updated;

    SceneEditorSelection newSelection = _state.selection;
    if (_state.selection.type == SceneEditorSelectionType.trajectoryPoint &&
        _state.selection.targetId == trajectoryId &&
        _state.selection.pointIndex != null) {
      final selIdx = _state.selection.pointIndex!;
      if (selIdx == pointIndex) {
        newSelection = const SceneEditorSelection.none();
      } else if (selIdx > pointIndex) {
        newSelection = SceneEditorSelection.trajectoryPoint(
          trajectoryId,
          selIdx - 1,
        );
      }
    }

    _commitSceneEdit(
      _state.scene.copyWith(trajectories: newTrajs),
      newSelection: newSelection,
    );
  }

  void changeTrajectoryColorHex(String trajectoryId, String colorHex) {
    final index = _state.scene.trajectories.indexWhere(
      (t) => t.id == trajectoryId,
    );
    if (index == -1) {
      throw SceneEditorTargetNotFoundException(
        'Trajectory with id $trajectoryId not found',
      );
    }

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
    final index = _state.scene.trajectories.indexWhere(
      (t) => t.id == trajectoryId,
    );
    if (index == -1) {
      throw SceneEditorTargetNotFoundException(
        'Trajectory with id $trajectoryId not found',
      );
    }

    final newTrajs = List<TrajectoryLine>.from(_state.scene.trajectories)
      ..removeAt(index);
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

    final newAnns = List<SceneAnnotation>.from(_state.scene.annotations)
      ..add(annotation);
    _commitSceneEdit(
      _state.scene.copyWith(annotations: newAnns),
      newSelection: SceneEditorSelection.annotation(annId),
    );
  }

  void moveAnnotation(String annotationId, TablePoint newPosition) {
    final clampedPos = _clampTablePoint(newPosition);
    final index = _state.scene.annotations.indexWhere(
      (a) => a.id == annotationId,
    );
    if (index == -1) {
      throw SceneEditorTargetNotFoundException(
        'Annotation with id $annotationId not found',
      );
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
    final index = _state.scene.annotations.indexWhere(
      (a) => a.id == annotationId,
    );
    if (index == -1) {
      throw SceneEditorTargetNotFoundException(
        'Annotation with id $annotationId not found',
      );
    }

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
    final index = _state.scene.annotations.indexWhere(
      (a) => a.id == annotationId,
    );
    if (index == -1) {
      throw SceneEditorTargetNotFoundException(
        'Annotation with id $annotationId not found',
      );
    }

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
    final index = _state.scene.annotations.indexWhere(
      (a) => a.id == annotationId,
    );
    if (index == -1) {
      throw SceneEditorTargetNotFoundException(
        'Annotation with id $annotationId not found',
      );
    }

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
    final index = _state.scene.annotations.indexWhere(
      (a) => a.id == annotationId,
    );
    if (index == -1) {
      throw SceneEditorTargetNotFoundException(
        'Annotation with id $annotationId not found',
      );
    }

    final newAnns = List<SceneAnnotation>.from(_state.scene.annotations)
      ..removeAt(index);
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
    final currentConfig =
        _state.scene.presentationConfig ?? const ScenePresentationConfig();
    final updatedConfig = ScenePresentationConfig(
      legacySystemIndex: legacySystemIndex ?? currentConfig.legacySystemIndex,
      legacyViewTypeIndex:
          legacyViewTypeIndex ?? currentConfig.legacyViewTypeIndex,
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

    final isDirty = !_areScenesIdentical(previousScene, _savedBaseline);
    final sanitizedSel = sanitizeSelection(
      previousScene,
      _state.selection,
      isHistoryNavigation: true,
    );

    _state = _state.copyWith(
      scene: previousScene,
      selection: sanitizedSel,
      isDirty: isDirty,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
      errorMessage: () => null,
    );
    _notifyListeners();
  }

  void redo() {
    if (!_history.canRedo) return;

    final nextScene = _history.redo(_state.scene);
    if (nextScene == null) return;

    final isDirty = !_areScenesIdentical(nextScene, _savedBaseline);
    final sanitizedSel = sanitizeSelection(
      nextScene,
      _state.selection,
      isHistoryNavigation: true,
    );

    _state = _state.copyWith(
      scene: nextScene,
      selection: sanitizedSel,
      isDirty: isDirty,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
      errorMessage: () => null,
    );
    _notifyListeners();
  }

  /// Sets the current scene state as the saved baseline (`isDirty = false`).
  void markSaved() {
    _savedBaseline = _state.scene;
    _state = _state.copyWith(isDirty: false);
    _notifyListeners();
  }

  /// Loads [scene] as a new editor session baseline.
  void loadScene(BilliardScene scene) {
    final frozen = _freezeScene(scene);
    _history.clear();
    _savedBaseline = frozen;
    _state = SceneEditorState(
      scene: frozen,
      activeTool: _state.activeTool,
      selection: const SceneEditorSelection.none(),
      isDirty: false,
      canUndo: false,
      canRedo: false,
    );
    _notifyListeners();
  }
}
