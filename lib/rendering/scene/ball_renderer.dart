// Ball rendering component for Billiardlearning Phase 3

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'scene_viewport.dart';
import 'scene_render_model.dart';

/// Component responsible for drawing billiard balls:
/// solid balls, striped/half balls, numbered balls, ghost shadows,
/// dashed outline balls, carom measles pattern, and 3D lighting highlights.
class BallRenderer {
  const BallRenderer();

  /// Renders measles pattern dots for carom billiard balls.
  void drawCaromDots(
    Canvas canvas,
    double ballRadius,
    Color ballColor,
    double opacity,
  ) {
    Color dotColor;
    if (ballColor.red > 180 && ballColor.green < 100 && ballColor.blue < 100) {
      // Red ball gets white/cream dots
      dotColor = Colors.white.withOpacity(opacity);
    } else {
      // White or Yellow ball gets dark red dots
      dotColor = const Color(0xFFD32F2F).withOpacity(opacity);
    }

    final Paint paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Center dot
    canvas.drawCircle(Offset.zero, ballRadius * 0.12, paint);

    // 5 outer dots symmetrically spaced
    final double radius = ballRadius * 0.55;
    for (int i = 0; i < 5; i++) {
      final double angle = i * 2 * math.pi / 5;
      canvas.drawCircle(
        Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        ballRadius * 0.12,
        paint,
      );
    }
  }

  /// Renders ghost shadow ball at trajectory start during rolling animation.
  void drawGhostShadow(
    Canvas canvas,
    SceneViewport viewport,
    BallRenderItem ball,
    double ballRadius,
    double lineScale,
  ) {
    final Offset actualPos = viewport.tablePointToOffset(ball.position);
    canvas.save();
    canvas.translate(actualPos.dx, actualPos.dy);
    canvas.rotate(ball.rotationInRadians);

    final ghostPaint = Paint()
      ..color = ball.color.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = ball.color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6 * lineScale;

    if (ball.ballTypeIndex == 0) {
      canvas.drawCircle(Offset.zero, ballRadius, ghostPaint);
      canvas.drawCircle(Offset.zero, ballRadius, strokePaint);
      canvas.drawLine(
        Offset(-ballRadius, 0),
        Offset(ballRadius, 0),
        strokePaint,
      );
      canvas.drawLine(
        Offset(0, -ballRadius),
        Offset(0, ballRadius),
        strokePaint,
      );
    } else if (ball.ballTypeIndex == 1) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: ballRadius),
        -math.pi / 2,
        math.pi,
        true,
        ghostPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: ballRadius),
        -math.pi / 2,
        math.pi,
        true,
        strokePaint,
      );
      canvas.drawLine(
        Offset(0, -ballRadius),
        Offset(0, ballRadius),
        strokePaint,
      );
    } else {
      canvas.drawCircle(Offset.zero, ballRadius, ghostPaint);
      canvas.drawCircle(Offset.zero, ballRadius, strokePaint);
    }
    canvas.restore();
  }

  /// Renders a single ball item onto the canvas.
  void drawBall(
    Canvas canvas,
    SceneViewport viewport,
    BallRenderItem ball,
    double ballRadius,
    double lineScale, {
    double additionalRotation = 0.0,
  }) {
    final Offset actualPos = viewport.tablePointToOffset(ball.position);

    canvas.save();
    canvas.translate(actualPos.dx, actualPos.dy);

    if (ball.isOutline) {
      canvas.save();
      canvas.rotate(ball.rotationInRadians);
      final strokePaint = Paint()
        ..color = ball.color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * lineScale;

      const int dashCount = 12;
      const double dashAngle = (2 * math.pi) / dashCount;
      for (int i = 0; i < dashCount; i++) {
        if (i % 2 == 0) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: ballRadius),
            i * dashAngle,
            dashAngle,
            false,
            strokePaint,
          );
        }
      }
      canvas.restore();
    } else if (ball.isGhost) {
      canvas.save();
      canvas.rotate(ball.rotationInRadians);
      final ghostPaint = Paint()
        ..color = ball.color.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = ball.color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 * lineScale;

      if (ball.ballTypeIndex == 0) {
        canvas.drawCircle(Offset.zero, ballRadius, ghostPaint);
        canvas.drawCircle(Offset.zero, ballRadius, strokePaint);
        canvas.drawLine(
          Offset(-ballRadius, 0),
          Offset(ballRadius, 0),
          strokePaint,
        );
        canvas.drawLine(
          Offset(0, -ballRadius),
          Offset(0, ballRadius),
          strokePaint,
        );
      } else if (ball.ballTypeIndex == 1) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: ballRadius),
          -math.pi / 2,
          math.pi,
          true,
          ghostPaint,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: ballRadius),
          -math.pi / 2,
          math.pi,
          true,
          strokePaint,
        );
        canvas.drawLine(
          Offset(0, -ballRadius),
          Offset(0, ballRadius),
          strokePaint,
        );
      } else if (ball.ballTypeIndex == 2) {
        canvas.drawCircle(Offset.zero, ballRadius, ghostPaint);
        canvas.drawCircle(Offset.zero, ballRadius, strokePaint);
        if (ball.text != null && ball.text!.isNotEmpty) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: ball.text,
              style: TextStyle(
                color: ball.color.withOpacity(0.9),
                fontSize: ballRadius * 1.1,
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
        }
      }
      canvas.restore();
    } else {
      // 3D rotating ball body with measles pattern
      final double totalRotation = ball.rotationInRadians + additionalRotation;

      // 1. Draw body and dots rotated
      canvas.save();
      canvas.rotate(totalRotation);
      canvas.drawCircle(
        Offset.zero,
        ballRadius,
        Paint()..color = ball.color.withOpacity(ball.opacity),
      );
      drawCaromDots(canvas, ballRadius, ball.color, ball.opacity);
      canvas.restore();

      // 2. Draw 3D specular highlight and ambient shadow overlay (stationary)
      final Rect rect = Rect.fromCircle(
        center: Offset.zero,
        radius: ballRadius,
      );
      final Paint highlightPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [
            Colors.white.withOpacity(0.65 * ball.opacity),
            Colors.white.withOpacity(0.2 * ball.opacity),
            Colors.transparent,
            Colors.black.withOpacity(0.45 * ball.opacity),
          ],
          stops: const [0.0, 0.35, 0.75, 1.0],
        ).createShader(rect);
      canvas.drawCircle(Offset.zero, ballRadius, highlightPaint);
    }
    canvas.restore();
  }
}
