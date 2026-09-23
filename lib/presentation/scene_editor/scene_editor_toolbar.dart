// Minimal Editor Toolbar for SceneEditor (Phase 4B)
// Binds Undo, Redo, and Tool buttons to SceneEditorController.

import 'package:flutter/material.dart';
import '../../application/scene_editor/scene_editor_controller.dart';
import '../../application/scene_editor/scene_editor_tool.dart';

class SceneEditorToolbar extends StatefulWidget {
  final SceneEditorController controller;

  const SceneEditorToolbar({super.key, required this.controller});

  @override
  State<SceneEditorToolbar> createState() => _SceneEditorToolbarState();
}

class _SceneEditorToolbarState extends State<SceneEditorToolbar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SceneEditorToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;

    return Material(
      color: Colors.black87,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              key: const Key('toolbar_undo_button'),
              icon: const Icon(Icons.undo),
              onPressed: state.canUndo ? () => widget.controller.undo() : null,
              tooltip: 'Undo',
            ),
            IconButton(
              key: const Key('toolbar_redo_button'),
              icon: const Icon(Icons.redo),
              onPressed: state.canRedo ? () => widget.controller.redo() : null,
              tooltip: 'Redo',
            ),
            const VerticalDivider(width: 1, color: Colors.white24),
            _buildToolIconButton(
              key: const Key('tool_select_button'),
              tool: SceneEditorTool.select,
              icon: Icons.near_me,
              label: 'Select',
            ),
            _buildToolIconButton(
              key: const Key('tool_move_button'),
              tool: SceneEditorTool.move,
              icon: Icons.open_with,
              label: 'Move',
            ),
            _buildToolIconButton(
              key: const Key('tool_ball_button'),
              tool: SceneEditorTool.ball,
              icon: Icons.circle,
              label: 'Ball',
            ),
            _buildToolIconButton(
              key: const Key('tool_ghost_ball_button'),
              tool: SceneEditorTool.ghostBall,
              icon: Icons.circle_outlined,
              label: 'Ghost Ball',
            ),
            _buildToolIconButton(
              key: const Key('tool_extra_ball_button'),
              tool: SceneEditorTool.extraBall,
              icon: Icons.add_circle_outline,
              label: 'Extra Ball',
            ),
            _buildToolIconButton(
              key: const Key('tool_trajectory_button'),
              tool: SceneEditorTool.trajectory,
              icon: Icons.timeline,
              label: 'Trajectory',
            ),
            _buildToolIconButton(
              key: const Key('tool_label_button'),
              tool: SceneEditorTool.label,
              icon: Icons.text_fields,
              label: 'Label',
            ),
            _buildToolIconButton(
              key: const Key('tool_cushion_number_button'),
              tool: SceneEditorTool.cushionNumber,
              icon: Icons.pin,
              label: 'Cushion Number',
            ),
            _buildToolIconButton(
              key: const Key('tool_delete_button'),
              tool: SceneEditorTool.delete,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolIconButton({
    required Key key,
    required SceneEditorTool tool,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.controller.state.activeTool == tool;
    return IconButton(
      key: key,
      icon: Icon(icon),
      color: isSelected ? Colors.amber : Colors.white70,
      onPressed: () => widget.controller.setTool(tool),
      tooltip: label,
    );
  }
}
