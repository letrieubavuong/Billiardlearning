// SceneRenderer widget facade for Billiardlearning Phase 3

import 'package:flutter/material.dart';
import 'scene_render_model.dart';
import 'scene_painter.dart';

/// Clean facade widget for rendering a [SceneRenderModel] using [ScenePainter].
class SceneRenderer extends StatelessWidget {
  final SceneRenderModel model;

  const SceneRenderer({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: ScenePainter(model: model),
        child: const SizedBox.expand(),
      ),
    );
  }
}
