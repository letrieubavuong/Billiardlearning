// SceneEditorCanvas Widget for Billiardlearning Phase 4B
// Flutter presentation wrapper binding pointer gestures to SceneEditorController.

import 'package:flutter/material.dart';
import '../../application/scene_editor/scene_editor_controller.dart';
import '../../application/scene_editor/scene_editor_exception.dart';
import '../../application/scene_editor/scene_editor_selection.dart';
import '../../application/scene_editor/scene_editor_tool.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../rendering/scene/legacy/legacy_render_adapter.dart';
import '../../rendering/scene/scene_renderer.dart';
import '../../rendering/scene/scene_viewport.dart';
import 'scene_editor_gesture_adapter.dart';
import 'scene_editor_hit_tester.dart';
import 'scene_editor_interaction_state.dart';
import 'scene_editor_overlay.dart';

class SceneEditorCanvas extends StatefulWidget {
  final SceneEditorController controller;
  final bool isVertical;
  final SceneViewMode? viewMode;
  final String? activeBallType;
  final String? activeBallLabel;
  final String? activeBallColorHex;
  final String activeCushionNumberText;
  final void Function(TablePoint position)? onLabelRequested;
  final ValueChanged<SceneEditorException>? onEditorError;

  const SceneEditorCanvas({
    super.key,
    required this.controller,
    this.isVertical = true,
    this.viewMode,
    this.activeBallType = 'red',
    this.activeBallLabel,
    this.activeBallColorHex,
    this.activeCushionNumberText = '20',
    this.onLabelRequested,
    this.onEditorError,
  });

  @override
  State<SceneEditorCanvas> createState() => _SceneEditorCanvasState();
}

class _SceneEditorCanvasState extends State<SceneEditorCanvas> {
  final SceneEditorGestureAdapter _adapter = const SceneEditorGestureAdapter();
  final SceneEditorHitTester _hitTester = const SceneEditorHitTester();

  SceneEditorInteractionState _interactionState =
      const SceneEditorInteractionState();
  SceneEditorTool? _lastObservedTool;

  @override
  void initState() {
    super.initState();
    _lastObservedTool = widget.controller.state.activeTool;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SceneEditorCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    _checkToolSwitch();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    _checkToolSwitch();
    if (mounted) {
      setState(() {});
    }
  }

  void _checkToolSwitch() {
    final currentTool = widget.controller.state.activeTool;
    if (_lastObservedTool != currentTool) {
      _cancelTransientDrag();
      if (_lastObservedTool == SceneEditorTool.trajectory &&
          currentTool != SceneEditorTool.trajectory) {
        // Clear active trajectory session when leaving trajectory tool
        _interactionState = _interactionState.copyWith(
          activeTrajectoryId: () => null,
        );
      }
      _lastObservedTool = currentTool;
    }
  }

  void _cancelTransientDrag() {
    if (_interactionState.isDragging) {
      setState(() {
        _interactionState = _interactionState.copyWith(
          isDragging: false,
          dragSelection: () => null,
          initialTablePoint: () => null,
          previewTablePoint: () => null,
        );
      });
    }
  }

  void _onTapDown(TapDownDetails details, SceneViewport viewport) {
    final localOffset = details.localPosition;
    final currentTool = widget.controller.state.activeTool;
    final currentScene = widget.controller.currentScene;

    // Check hit target
    final hitSelection = _hitTester.hitTest(
      localOffset,
      currentScene,
      viewport,
      widget.isVertical,
    );

    try {
      switch (currentTool) {
        case SceneEditorTool.select:
          if (hitSelection.type != SceneEditorSelectionType.none) {
            widget.controller.select(hitSelection);
          } else {
            widget.controller.clearSelection();
          }
          break;

        case SceneEditorTool.move:
          if (hitSelection.type != SceneEditorSelectionType.none) {
            widget.controller.select(hitSelection);
          }
          break;

        case SceneEditorTool.ball:
        case SceneEditorTool.ghostBall:
        case SceneEditorTool.extraBall:
          if (!_adapter.isPointInVisibleBounds(
            localOffset,
            viewport,
            widget.isVertical,
          )) {
            return;
          }
          final tapPt = _adapter.localOffsetToTablePoint(
            localOffset,
            viewport,
            widget.isVertical,
          );
          String ballType = 'red';
          if (currentTool == SceneEditorTool.ghostBall) {
            ballType = 'ghost';
          } else if (currentTool == SceneEditorTool.extraBall) {
            ballType = 'extra';
          } else {
            ballType = widget.activeBallType ?? 'red';
          }

          widget.controller.addBall(
            ballType: ballType,
            position: tapPt,
            label: widget.activeBallLabel,
            colorHex: widget.activeBallColorHex,
          );
          break;

        case SceneEditorTool.trajectory:
          if (!_adapter.isPointInVisibleBounds(
            localOffset,
            viewport,
            widget.isVertical,
          )) {
            return;
          }
          final tapPt = _adapter.localOffsetToTablePoint(
            localOffset,
            viewport,
            widget.isVertical,
          );
          final activeTrajId = _interactionState.activeTrajectoryId;

          if (activeTrajId == null ||
              !currentScene.trajectories.any((t) => t.id == activeTrajId)) {
            // Create new trajectory line
            widget.controller.addTrajectory(points: [tapPt]);
            final newTrajId = widget.controller.state.selection.targetId;
            setState(() {
              _interactionState = _interactionState.copyWith(
                activeTrajectoryId: () => newTrajId,
              );
            });
          } else {
            // Add point to active trajectory line
            widget.controller.addTrajectoryPoint(activeTrajId, tapPt);
          }
          break;

        case SceneEditorTool.label:
          if (!_adapter.isPointInVisibleBounds(
            localOffset,
            viewport,
            widget.isVertical,
          )) {
            return;
          }
          final tapPt = _adapter.localOffsetToTablePoint(
            localOffset,
            viewport,
            widget.isVertical,
          );
          if (widget.onLabelRequested != null) {
            widget.onLabelRequested!(tapPt);
          }
          // Note: If onLabelRequested is null, do NOT commit placeholder annotation
          break;

        case SceneEditorTool.cushionNumber:
          final railHit = _adapter.detectRailRegion(
            localOffset,
            viewport,
            widget.isVertical,
          );
          if (railHit == null) return;

          widget.controller.addAnnotation(
            text: widget.activeCushionNumberText,
            position: railHit.projectedPoint,
            colorHex: '#FFD700',
            role: 'cushionNumber',
            cushionSide: railHit.side,
          );
          break;

        case SceneEditorTool.delete:
          if (hitSelection.type == SceneEditorSelectionType.none) return;
          switch (hitSelection.type) {
            case SceneEditorSelectionType.ball:
              widget.controller.deleteBall(hitSelection.targetId!);
              break;
            case SceneEditorSelectionType.annotation:
              widget.controller.deleteAnnotation(hitSelection.targetId!);
              break;
            case SceneEditorSelectionType.trajectory:
              widget.controller.deleteTrajectory(hitSelection.targetId!);
              break;
            case SceneEditorSelectionType.trajectoryPoint:
              widget.controller.removeTrajectoryPoint(
                hitSelection.targetId!,
                hitSelection.pointIndex!,
              );
              break;
            case SceneEditorSelectionType.none:
              break;
          }
          break;
      }
    } on SceneEditorException catch (e) {
      if (widget.onEditorError != null) {
        widget.onEditorError!(e);
      }
    }
  }

  void _onPanStart(DragStartDetails details, SceneViewport viewport) {
    final currentTool = widget.controller.state.activeTool;
    if (currentTool != SceneEditorTool.select &&
        currentTool != SceneEditorTool.move) {
      return;
    }

    final localOffset = details.localPosition;
    final currentScene = widget.controller.currentScene;

    var hitSelection = _hitTester.hitTest(
      localOffset,
      currentScene,
      viewport,
      widget.isVertical,
    );

    if (hitSelection.type == SceneEditorSelectionType.none) {
      final activeSel = widget.controller.state.selection;
      if (activeSel.type != SceneEditorSelectionType.none) {
        hitSelection = activeSel;
      } else {
        return;
      }
    }

    widget.controller.select(hitSelection);

    final startPt = _adapter.localOffsetToTablePoint(
      localOffset,
      viewport,
      widget.isVertical,
    );

    setState(() {
      _interactionState = _interactionState.copyWith(
        isDragging: true,
        dragSelection: () => hitSelection,
        initialTablePoint: () => startPt,
        previewTablePoint: () => startPt,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details, SceneViewport viewport) {
    if (!_interactionState.isDragging ||
        _interactionState.dragSelection == null) {
      return;
    }

    final localOffset = details.localPosition;
    final newTablePt = _adapter.localOffsetToTablePoint(
      localOffset,
      viewport,
      widget.isVertical,
    );

    setState(() {
      _interactionState = _interactionState.copyWith(
        previewTablePoint: () => newTablePt,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_interactionState.isDragging ||
        _interactionState.dragSelection == null ||
        _interactionState.previewTablePoint == null) {
      _cancelTransientDrag();
      return;
    }

    final sel = _interactionState.dragSelection!;
    final finalPt = _interactionState.previewTablePoint!;

    // Commit EXACTLY ONE controller mutation at drag release
    try {
      switch (sel.type) {
        case SceneEditorSelectionType.ball:
          widget.controller.moveBall(sel.targetId!, finalPt);
          break;
        case SceneEditorSelectionType.annotation:
          widget.controller.moveAnnotation(sel.targetId!, finalPt);
          break;
        case SceneEditorSelectionType.trajectoryPoint:
          widget.controller.moveTrajectoryPoint(
            sel.targetId!,
            sel.pointIndex!,
            finalPt,
          );
          break;
        case SceneEditorSelectionType.trajectory:
        case SceneEditorSelectionType.none:
          break;
      }
    } on SceneEditorException catch (e) {
      if (widget.onEditorError != null) {
        widget.onEditorError!(e);
      }
    } finally {
      _cancelTransientDrag();
    }
  }

  void _onPanCancel() {
    _cancelTransientDrag();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size.width <= 0 || size.height <= 0) {
          return const SizedBox.shrink();
        }

        final canonicalScene = widget.controller.currentScene;
        final renderScene = _interactionState.getPreviewScene(canonicalScene);

        final effectiveScene = widget.viewMode != null
            ? renderScene.copyWith(
                presentationConfig: ScenePresentationConfig(
                  legacySystemIndex:
                      renderScene.presentationConfig?.legacySystemIndex ?? 0,
                  legacyViewTypeIndex: widget.viewMode!.index,
                  labelFontSize: renderScene.presentationConfig?.labelFontSize,
                ),
              )
            : renderScene;

        final renderModel = LegacyRenderAdapter.sceneToRenderModel(
          scene: effectiveScene,
          isVertical: widget.isVertical,
        );

        final viewport = SceneViewport(
          canvasSize: size,
          viewMode: renderModel.viewMode,
          isVertical: renderModel.isVertical,
          hasBottomRail: renderModel.hasBottomRail,
        );

        final selection = widget.controller.state.selection;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _onTapDown(details, viewport),
          onPanStart: (details) => _onPanStart(details, viewport),
          onPanUpdate: (details) => _onPanUpdate(details, viewport),
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SceneRenderer(model: renderModel),
              CustomPaint(
                size: size,
                painter: SceneEditorOverlay(
                  scene: renderScene,
                  selection: selection,
                  viewport: viewport,
                  isVertical: widget.isVertical,
                  adapter: _adapter,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
