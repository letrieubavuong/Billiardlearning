// Annotation rendering component for Billiardlearning Phase 3

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'scene_viewport.dart';
import 'scene_render_model.dart';

/// Component responsible for drawing text annotations, angle indicator arcs,
/// and cue ball spin/effet mini-diagrams.
class AnnotationRenderer {
  const AnnotationRenderer();

  /// Renders text labels onto the canvas.
  void drawAnnotations(
    Canvas canvas,
    SceneViewport viewport,
    List<AnnotationRenderItem> annotations,
    SceneRenderTheme theme,
    double textScale,
  ) {
    for (final label in annotations) {
      final Offset actualPos = viewport.tablePointToOffset(label.position);

      canvas.save();
      canvas.translate(actualPos.dx, actualPos.dy);
      canvas.rotate(label.rotationInRadians);

      final Color labelColor =
          (label.role != null && theme.indicatorColors.containsKey(label.role))
          ? theme.indicatorColors[label.role]!
          : label.color;

      final textPainter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: labelColor,
            fontSize: label.fontSize * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  /// Renders angle arcs and angle label text.
  void drawAngles(
    Canvas canvas,
    SceneViewport viewport,
    List<AngleRenderItem> angles,
    SceneRenderTheme theme,
    double lineScale,
    double textScale,
  ) {
    for (final angle in angles) {
      final Offset posA = viewport.tablePointToOffset(angle.a);
      final Offset posB = viewport.tablePointToOffset(angle.b);
      final Offset posC = viewport.tablePointToOffset(angle.c);

      final double startAngle = math.atan2(
        posA.dy - posB.dy,
        posA.dx - posB.dx,
      );
      final double endAngle = math.atan2(posC.dy - posB.dy, posC.dx - posB.dx);
      double sweepAngle = endAngle - startAngle;

      if (sweepAngle > math.pi) sweepAngle -= 2 * math.pi;
      if (sweepAngle < -math.pi) sweepAngle += 2 * math.pi;

      final Color angleColor =
          (angle.role != null && theme.indicatorColors.containsKey(angle.role))
          ? theme.indicatorColors[angle.role]!
          : angle.color;

      final Paint anglePaint = Paint()
        ..color = angleColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * lineScale;

      canvas.drawArc(
        Rect.fromCircle(center: posB, radius: angle.radius * lineScale),
        startAngle,
        sweepAngle,
        false,
        anglePaint,
      );

      final double midAngle = startAngle + sweepAngle / 2;
      final double degreeValue = (sweepAngle.abs() * 180 / math.pi);
      final String degreeText =
          angle.label ?? "${degreeValue.toStringAsFixed(1)}°";

      final Offset labelPos = Offset(
        posB.dx +
            math.cos(midAngle) * (angle.radius * lineScale + 12 * textScale),
        posB.dy +
            math.sin(midAngle) * (angle.radius * lineScale + 12 * textScale),
      );

      _drawTextCentered(
        canvas,
        degreeText,
        labelPos,
        8 * textScale,
        color: angleColor,
      );
    }
  }

  /// Renders mini cue ball spin (effet) overlay.
  void drawMiniEffet(
    Canvas canvas,
    SceneViewport viewport,
    EffetRenderData effetData,
    double lineScale,
    double textScale,
  ) {
    final spots = effetData.spots;
    final bool showHitBall = effetData.showHitBall;
    final int hitThickness = effetData.hitThickness;
    final String hitSide = effetData.hitSide;
    final double spotSize = effetData.spotSize;

    final double miniSize = (viewport.playAreaWidth * 0.24).clamp(55.0, 95.0);
    final double miniRadius = miniSize / 2;

    final double w = viewport.isVertical
        ? viewport.canvasSize.width
        : viewport.canvasSize.height;
    final double centerX = w - miniRadius - 2.0;
    final double centerY = miniRadius + 2.0;

    final double ballRadius = showHitBall ? (miniSize / 2.8) : miniRadius;

    Offset cueCenter = Offset(centerX, centerY);
    Offset targetCenter = Offset(centerX, centerY);

    if (showHitBall) {
      final double centerDist = 2 * ballRadius * (1 - hitThickness / 12);
      final double halfDist = centerDist / 2;
      if (hitSide == 'right') {
        cueCenter = Offset(centerX + halfDist, centerY);
        targetCenter = Offset(centerX - halfDist, centerY);
      } else {
        cueCenter = Offset(centerX - halfDist, centerY);
        targetCenter = Offset(centerX + halfDist, centerY);
      }
    }

    // Target object ball (red)
    if (showHitBall) {
      final Paint targetBgPaint = Paint()
        ..color = Colors.red.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(targetCenter, ballRadius, targetBgPaint);

      final Paint targetBorderPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * lineScale;
      canvas.drawCircle(targetCenter, ballRadius, targetBorderPaint);
    }

    // Cue ball (white)
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFF9F9F9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(cueCenter, ballRadius, bgPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * lineScale;
    canvas.drawCircle(cueCenter, ballRadius, borderPaint);

    // Concentric rings
    final Paint ringPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4 * lineScale;
    canvas.drawCircle(cueCenter, ballRadius * 0.5, ringPaint);

    // Crosshairs
    final Paint linePaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 0.6 * lineScale;
    canvas.drawLine(
      Offset(cueCenter.dx - ballRadius, cueCenter.dy),
      Offset(cueCenter.dx + ballRadius, cueCenter.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(cueCenter.dx, cueCenter.dy - ballRadius),
      Offset(cueCenter.dx, cueCenter.dy + ballRadius),
      linePaint,
    );

    // Spin spots
    final double computedSpotRadius = 3.5 * (spotSize / 25.0) * lineScale;
    for (final spot in spots) {
      final double dx = (spot['x'] as num).toDouble();
      final double dy = (spot['y'] as num).toDouble();
      final String text = spot['number']?.toString() ?? '';
      final Color color = Color(spot['color'] ?? Colors.teal.value);

      final Offset spotCenter = Offset(
        cueCenter.dx + dx * ballRadius,
        cueCenter.dy + dy * ballRadius,
      );

      final Paint spotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(spotCenter, computedSpotRadius, spotPaint);

      final Paint spotBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 * lineScale;
      canvas.drawCircle(spotCenter, computedSpotRadius, spotBorder);

      final Color textColor = color.computeLuminance() > 0.6
          ? Colors.black87
          : Colors.white;

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: 4.5 * (spotSize / 25.0) * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(spotCenter.dx - tp.width / 2, spotCenter.dy - tp.height / 2),
      );
    }
  }

  void _drawTextCentered(
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
}
