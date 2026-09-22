// Table rendering component for Billiardlearning Phase 3

import 'package:flutter/material.dart';
import 'scene_viewport.dart';
import 'scene_render_model.dart';

/// Component responsible for drawing the billiard table:
/// felt/cloth, cushions, wood rails, grid lines, minor ticks,
/// diamond marks, and DiagramSystem overlays.
class TableRenderer {
  const TableRenderer();

  /// Utility to paint centered text at a pixel offset.
  void drawText(
    Canvas canvas,
    String text,
    Offset position,
    double fontSize, {
    Color color = Colors.white,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  /// Renders table cloth and cushions.
  void drawClothAndCushions(
    Canvas canvas,
    SceneViewport viewport,
    SceneRenderTheme theme,
  ) {
    // Playfield background (cloth)
    canvas.drawRect(viewport.playfieldRect, Paint()..color = theme.clothColor);

    // Cushion borders
    final Paint cushionPaint = Paint()..color = theme.cushionColor;
    final double woodRail = viewport.woodRailWidth;
    final double cushion = viewport.cushionWidth;
    final double totalRail = viewport.totalRail;
    final double w = viewport.isVertical
        ? viewport.canvasSize.width
        : viewport.canvasSize.height;
    final double h = viewport.isVertical
        ? viewport.canvasSize.height
        : viewport.canvasSize.width;
    final bool hasRightRail =
        viewport.viewMode != SceneViewMode.halfWidth &&
        viewport.viewMode != SceneViewMode.halfWidthHalfLength &&
        viewport.viewMode != SceneViewMode.halfWidthThirdLength &&
        viewport.viewMode != SceneViewMode.halfWidthQuarterLength;

    final double verticalCushionHeight = viewport.playAreaHeight + cushion;

    // Top cushion
    canvas.drawRect(
      Rect.fromLTWH(
        woodRail,
        woodRail,
        w - woodRail - (hasRightRail ? woodRail : 0),
        cushion,
      ),
      cushionPaint,
    );

    // Left cushion
    canvas.drawRect(
      Rect.fromLTWH(woodRail, woodRail, cushion, verticalCushionHeight),
      cushionPaint,
    );

    // Right cushion
    if (hasRightRail) {
      canvas.drawRect(
        Rect.fromLTWH(w - totalRail, woodRail, cushion, verticalCushionHeight),
        cushionPaint,
      );
    }

    // Bottom cushion
    if (viewport.hasBottomRail) {
      canvas.drawRect(
        Rect.fromLTWH(
          woodRail,
          h - totalRail,
          w - woodRail - (hasRightRail ? woodRail : 0),
          cushion,
        ),
        cushionPaint,
      );
    }
  }

  /// Renders grid lines, minor ticks, and diamond marks.
  void drawGridAndDiamonds(
    Canvas canvas,
    SceneViewport viewport,
    SceneRenderTheme theme,
    double lineScale,
  ) {
    final double totalRail = viewport.totalRail;
    final double playAreaWidth = viewport.playAreaWidth;
    final double playAreaHeight = viewport.playAreaHeight;
    final double diamondSpacing = viewport.diamondSpacing;
    final int hSegments = viewport.hSegments;
    final bool hasRightRail =
        viewport.viewMode != SceneViewMode.halfWidth &&
        viewport.viewMode != SceneViewMode.halfWidthHalfLength &&
        viewport.viewMode != SceneViewMode.halfWidthThirdLength &&
        viewport.viewMode != SceneViewMode.halfWidthQuarterLength;
    final double w = viewport.isVertical
        ? viewport.canvasSize.width
        : viewport.canvasSize.height;
    final double h = viewport.isVertical
        ? viewport.canvasSize.height
        : viewport.canvasSize.width;
    final double woodRail = viewport.woodRailWidth;
    final double cushion = viewport.cushionWidth;

    // Main grid lines
    final Paint gridPaint = Paint()
      ..color = theme.gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4 * lineScale;

    for (int i = 1; i < hSegments; i++) {
      final double x = totalRail + i * diamondSpacing;
      canvas.drawLine(
        Offset(x, totalRail),
        Offset(x, totalRail + playAreaHeight),
        gridPaint,
      );
    }
    final int vSegments = (playAreaHeight / diamondSpacing).floor();
    for (int i = 1; i <= vSegments; i++) {
      final double y = totalRail + i * diamondSpacing;
      canvas.drawLine(
        Offset(totalRail, y),
        Offset(totalRail + playAreaWidth, y),
        gridPaint,
      );
    }

    // Minor ticks on cushions
    final minorTickPaint = Paint()
      ..color = Colors.white.withOpacity(0.42)
      ..strokeWidth = 0.65 * lineScale
      ..strokeCap = StrokeCap.round;

    final int horizontalTickSegments = hSegments;
    final int verticalTickSegments = (playAreaHeight / diamondSpacing).round();

    for (int segment = 0; segment < horizontalTickSegments; segment++) {
      for (int unit = 1; unit < 10; unit++) {
        final x = totalRail + (segment + unit / 10.0) * diamondSpacing;
        final length = cushion * (unit == 5 ? 0.55 : 0.34);
        canvas.drawLine(
          Offset(x, totalRail),
          Offset(x, totalRail - length),
          minorTickPaint,
        );
        if (viewport.hasBottomRail) {
          final bottom = totalRail + playAreaHeight;
          canvas.drawLine(
            Offset(x, bottom),
            Offset(x, bottom + length),
            minorTickPaint,
          );
        }
      }
    }

    for (int segment = 0; segment < verticalTickSegments; segment++) {
      for (int unit = 1; unit < 10; unit++) {
        final y = totalRail + (segment + unit / 10.0) * diamondSpacing;
        if (y > totalRail + playAreaHeight) continue;
        final length = cushion * (unit == 5 ? 0.55 : 0.34);
        canvas.drawLine(
          Offset(totalRail, y),
          Offset(totalRail - length, y),
          minorTickPaint,
        );
        if (hasRightRail) {
          final right = totalRail + playAreaWidth;
          canvas.drawLine(
            Offset(right, y),
            Offset(right + length, y),
            minorTickPaint,
          );
        }
      }
    }

    // Diamond dots
    final Paint diamondPaint = Paint()..color = theme.diamondColor;
    for (int i = 0; i <= hSegments; i++) {
      final double x = totalRail + i * diamondSpacing;
      canvas.drawCircle(
        Offset(x, woodRail / 2),
        1.45 * lineScale,
        diamondPaint,
      );
      if (viewport.hasBottomRail) {
        canvas.drawCircle(
          Offset(x, h - woodRail / 2),
          1.45 * lineScale,
          diamondPaint,
        );
      }
    }
    for (int i = 0; i <= (playAreaHeight / diamondSpacing).round(); i++) {
      final double y = totalRail + i * diamondSpacing;
      if (y <= h) {
        canvas.drawCircle(
          Offset(woodRail / 2, y),
          1.45 * lineScale,
          diamondPaint,
        );
        if (hasRightRail) {
          canvas.drawCircle(
            Offset(w - woodRail / 2, y),
            1.45 * lineScale,
            diamondPaint,
          );
        }
      }
    }
  }

  /// Renders DiagramSystem numerical overlays (e.g. xohaibang, babangcha).
  void drawSystemOverlay(
    Canvas canvas,
    SceneViewport viewport,
    int systemIndex,
    double textScale,
  ) {
    // 4: xohaibang, 5: babangcha
    if (systemIndex != 4 && systemIndex != 5) return;

    final double totalRail = viewport.totalRail;
    final double diamondSpacing = viewport.diamondSpacing;
    final double woodRail = viewport.woodRailWidth;
    final double playAreaHeight = viewport.playAreaHeight;
    final double w = viewport.isVertical
        ? viewport.canvasSize.width
        : viewport.canvasSize.height;
    final double h = viewport.isVertical
        ? viewport.canvasSize.height
        : viewport.canvasSize.width;

    if (systemIndex == 4) {
      // xohaibang overlay
      for (int i = 0; i <= 4; i++) {
        final double x = totalRail + i * diamondSpacing;
        drawText(
          canvas,
          "${i + 1}",
          Offset(x, woodRail / 2 - 8 * textScale),
          9 * textScale,
          color: Colors.yellow,
        );
      }
      if (viewport.hasBottomRail) {
        for (int i = 0; i <= 4; i++) {
          final double x = totalRail + i * diamondSpacing;
          drawText(
            canvas,
            "$i",
            Offset(x, h - woodRail / 2 + 8 * textScale),
            9 * textScale,
            color: Colors.white,
          );
        }
      }
      final int vCount = (playAreaHeight / diamondSpacing).round();
      for (int i = vCount; i >= 0; i--) {
        final double y = totalRail + i * diamondSpacing;
        if (y <= h) {
          drawText(
            canvas,
            "${vCount - i}",
            Offset(woodRail / 2 - 10 * textScale, y),
            9 * textScale,
            color: Colors.cyanAccent,
          );
        }
      }
    } else if (systemIndex == 5) {
      // babangcha overlay
      for (int i = 1; i <= 4; i++) {
        double x;
        if (i < 4 && i >= 3) {
          x = totalRail + 2.5 * diamondSpacing;
          drawText(
            canvas,
            "-1",
            Offset(x, woodRail / 2 - 8 * textScale),
            11 * textScale,
            color: Colors.red,
          );
        }
        if (i < 3 && i >= 2) {
          x = totalRail + 1.5 * diamondSpacing;
          drawText(
            canvas,
            "-2",
            Offset(x, woodRail / 2 - 8 * textScale),
            11 * textScale,
            color: Colors.red,
          );
        }
      }
      for (int v = 1; v <= 12; v++) {
        double nodeY;
        if (v <= 4) {
          nodeY = v * 0.5;
        } else {
          nodeY = 2.0 + (v - 4) * 0.25;
        }
        final double y = totalRail + nodeY * diamondSpacing;
        if (y <= h - woodRail) {
          drawText(
            canvas,
            "$v",
            Offset(woodRail / 2 - 10 * textScale, y),
            11 * textScale,
            color: Colors.lightGreenAccent,
          );
        }
      }
      for (int v = 1; v <= 12; v++) {
        double nodeY;
        if (v <= 8) {
          nodeY = v * 0.5;
        } else {
          nodeY = 4.0 + (v - 8);
        }
        final double y = totalRail + nodeY * diamondSpacing;
        if (y <= h - woodRail) {
          drawText(
            canvas,
            "$v",
            Offset(w - woodRail / 2 + 10 * textScale, y),
            11 * textScale,
            color: Colors.white,
          );
        }
      }
    }
  }
}
