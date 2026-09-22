import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'billiard_diagram.dart';
import 'shot_details.dart';
import 'animated_article_block.dart';
import '../screens/fullscreen_billiard_viewer.dart';
import 'animated_text_widget.dart';

class ArticleBlocks {
  static Widget text(String heading, String text) {
    return AnimatedArticleBlock(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.yellow[400],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.5),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  static Widget section(int number, String title, Color color, {String? text}) {
    return Builder(
      builder: (context) {
        final themeColor = Theme.of(context).colorScheme.primary;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnimatedArticleBlock(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (text != null && text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget subSection(String title, Color color, {String? text}) {
    return Builder(
      builder: (context) {
        final themeColor = Theme.of(context).colorScheme.secondary;
        return AnimatedArticleBlock(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                if (text != null && text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget headingText(String text, {double bottomPadding = 8}) {
    return AnimatedArticleBlock(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, height: 1.5),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  static Widget iconText(
    IconData icon,
    Color color,
    String text, {
    double bottomPadding = 10,
  }) {
    return AnimatedArticleBlock(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget formula(
    String content,
    Color defaultColor, {
    double bottomPadding = 12,
  }) {
    Map<String, dynamic> data = {};
    if (content.startsWith('{') && content.endsWith('}')) {
      try {
        data = jsonDecode(content);
      } catch (_) {}
    }

    final String text = data.containsKey('text') ? data['text'] : content;
    final Color borderColor = data['colorVal'] != null
        ? Color(data['colorVal'])
        : defaultColor;
    final Color textColor = data['textColorVal'] != null
        ? Color(data['textColorVal'])
        : borderColor;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: bottomPadding),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: borderColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  static Widget details({
    required Offset effet,
    required double thickness,
    double cueAngle = 0,
    String? forceImage,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: ImpactIndicator(
              thickness: thickness,
              effet: effet,
              cueAngle: cueAngle,
              forceImagePath: forceImage,
              size: 85,
            ),
          ),
        );
      },
    );
  }

  static Widget image(BuildContext context, String assetPath, String caption) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Container(
                    height: 150,
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static Widget diagram({
    required List<Ball> balls,
    List<BallPath>? paths,
    List<BilliardLabel>? labels,
    List<BilliardAngle>? angles,
    DiagramSystem system = DiagramSystem.standard,
    TableViewType viewType = TableViewType.full,
    bool isVertical = false,
    Map<String, dynamic>? effetData,
    List<String>? stepTexts,
    List<Map<String, dynamic>>? stepScripts,
  }) {
    final diagramWidget = BilliardDiagram(
      balls: balls,
      paths: paths,
      labels: labels,
      angles: angles,
      system: system,
      viewType: viewType,
      isVertical: isVertical,
      effetData: effetData,
      stepTexts: stepTexts,
      stepScripts: stepScripts,
    );
    return Builder(
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FullscreenBilliardViewer(child: diagramWidget),
                ),
              );
            },
            child: diagramWidget,
          ),
        );
      },
    );
  }

  static Widget dataTable(List<List<String>> data, {Color? headerColor}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final onSurface = Theme.of(context).colorScheme.onSurface;
        final borderCol = onSurface.withOpacity(0.12);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(color: borderCol),
              ),
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: borderCol),
                ),
                children: data.map((row) {
                  bool isHeader = data.indexOf(row) == 0;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: isHeader
                          ? (headerColor ??
                                (isDark
                                    ? Colors.blueGrey.withOpacity(0.2)
                                    : Colors.blueGrey.withOpacity(0.1)))
                          : null,
                    ),
                    children: row.map((cell) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        child: Text(
                          cell,
                          style: TextStyle(
                            fontSize: isHeader ? 14 : 13,
                            fontWeight: isHeader
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isHeader
                                ? onSurface
                                : onSurface.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget effetDiagram(dynamic blockData) {
    List<dynamic> spots = [];
    bool showHitBall = false;
    int hitThickness = 6;
    String hitSide = 'right';
    double spotSize = 25.0;

    if (blockData is Map<String, dynamic>) {
      spots = blockData['spots'] ?? [];
      showHitBall = blockData['showHitBall'] ?? false;
      hitThickness = blockData['hitThickness'] ?? 6;
      hitSide = blockData['hitSide'] ?? 'right';
      spotSize = (blockData['spotSize'] as num?)?.toDouble() ?? 25.0;
    } else if (blockData is List) {
      spots = blockData;
    }

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullscreenBilliardViewer(
                    child: Center(
                      child: SizedBox(
                        width: showHitBall ? 320 : 250,
                        height: 250,
                        child: CustomPaint(
                          size: Size(showHitBall ? 320 : 250, 250),
                          painter: EffetDiagramPainter(
                            spots,
                            showHitBall: showHitBall,
                            hitThickness: hitThickness,
                            hitSide: hitSide,
                            spotSize: spotSize * 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SizedBox(
                  width: showHitBall ? 220 : 150,
                  height: 150,
                  child: CustomPaint(
                    size: Size(showHitBall ? 220 : 150, 150),
                    painter: EffetDiagramPainter(
                      spots,
                      showHitBall: showHitBall,
                      hitThickness: hitThickness,
                      hitSide: hitSide,
                      spotSize: spotSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget animatedText({
    required String text,
    required String type,
    required Color color,
    required double fontSize,
    required double speed,
  }) {
    return AnimatedTextWidget(
      text: text,
      type: type,
      color: color,
      fontSize: fontSize,
      speed: speed,
    );
  }
}

class EffetDiagramPainter extends CustomPainter {
  final List<dynamic> spots;
  final bool showHitBall;
  final int hitThickness;
  final String hitSide;
  final double spotSize;

  EffetDiagramPainter(
    this.spots, {
    this.showHitBall = false,
    this.hitThickness = 6,
    this.hitSide = 'right',
    this.spotSize = 25.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.height / 2;
    final Offset canvasCenter = Offset(size.width / 2, size.height / 2);

    final double ballRadius = showHitBall ? (size.height / 2.8) : radius;

    // Calculate centers
    Offset cueCenter = canvasCenter;
    Offset targetCenter = canvasCenter;

    if (showHitBall) {
      final double centerDist = 2 * ballRadius * (1 - hitThickness / 12);
      final double halfDist = centerDist / 2;
      if (hitSide == 'right') {
        cueCenter = Offset(canvasCenter.dx + halfDist, canvasCenter.dy);
        targetCenter = Offset(canvasCenter.dx - halfDist, canvasCenter.dy);
      } else {
        cueCenter = Offset(canvasCenter.dx - halfDist, canvasCenter.dy);
        targetCenter = Offset(canvasCenter.dx + halfDist, canvasCenter.dy);
      }
    }

    // Draw target/object ball (Red)
    if (showHitBall) {
      final Paint targetBgPaint = Paint()
        ..color = Colors.red.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(targetCenter, ballRadius, targetBgPaint);

      final Paint targetBorderPaint = Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(targetCenter, ballRadius, targetBorderPaint);

      // Draw 12 vertical thickness lines on target ball
      final Paint targetLinePaint = Paint()
        ..color = Colors.red.withOpacity(0.25)
        ..strokeWidth = 0.5;

      for (int i = 1; i < 12; i++) {
        final double lx =
            targetCenter.dx - ballRadius + (2 * ballRadius * i) / 12;
        final double dx = (lx - targetCenter.dx).abs();
        final double dy = math.sqrt(ballRadius * ballRadius - dx * dx);
        canvas.drawLine(
          Offset(lx, targetCenter.dy - dy),
          Offset(lx, targetCenter.dy + dy),
          targetLinePaint,
        );
      }

      // Draw target ball vertical & horizontal main axis
      final Paint targetAxisPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.4)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(targetCenter.dx - ballRadius, targetCenter.dy),
        Offset(targetCenter.dx + ballRadius, targetCenter.dy),
        targetAxisPaint,
      );
      canvas.drawLine(
        Offset(targetCenter.dx, targetCenter.dy - ballRadius),
        Offset(targetCenter.dx, targetCenter.dy + ballRadius),
        targetAxisPaint,
      );
    }

    // Draw background circle (White cue ball)
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFF9F9F9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(cueCenter, ballRadius, bgPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(cueCenter, ballRadius, borderPaint);

    // Draw Concentric circles (4 layers)
    final Paint ringPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(cueCenter, ballRadius * (i / 4), ringPaint);
    }

    // Draw clock-hour division lines (every 30 degrees)
    final Paint clockLinePaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 0.6;
    for (int hour = 1; hour <= 12; hour++) {
      if (hour % 3 == 0) continue; // Skip 12, 3, 6, 9
      final double angle = (hour * 30) * math.pi / 180;
      final double cosA = math.cos(angle);
      final double sinA = math.sin(angle);
      canvas.drawLine(
        Offset(
          cueCenter.dx - cosA * ballRadius,
          cueCenter.dy - sinA * ballRadius,
        ),
        Offset(
          cueCenter.dx + cosA * ballRadius,
          cueCenter.dy + sinA * ballRadius,
        ),
        clockLinePaint,
      );
    }

    // Draw 8 vertical division lines (chia bi thành 8 phần)
    final Paint divisionLinePaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..strokeWidth = 0.6;
    for (int i = 1; i < 8; i++) {
      if (i == 4) continue; // Skip the center vertical line
      final double x = cueCenter.dx - ballRadius + (ballRadius * 2 * i) / 8;
      final double dx = (x - cueCenter.dx).abs();
      final double dy = math.sqrt(ballRadius * ballRadius - dx * dx);
      canvas.drawLine(
        Offset(x, cueCenter.dy - dy),
        Offset(x, cueCenter.dy + dy),
        divisionLinePaint,
      );
    }

    // Draw 8 horizontal division lines (chia bi thành 8 phần ngang)
    for (int i = 1; i < 8; i++) {
      if (i == 4) continue; // Skip the center horizontal line
      final double y = cueCenter.dy - ballRadius + (ballRadius * 2 * i) / 8;
      final double dy = (y - cueCenter.dy).abs();
      final double dx = math.sqrt(ballRadius * ballRadius - dy * dy);
      canvas.drawLine(
        Offset(cueCenter.dx - dx, y),
        Offset(cueCenter.dx + dx, y),
        divisionLinePaint,
      );
    }

    // Draw crosshairs
    final Paint linePaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1.2;
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

    // Draw spots (Proportional size: radius 8.0 * (spotSize / 25.0))
    final double computedSpotRadius = 8.0 * (spotSize / 25.0);
    for (var spot in spots) {
      final double dx = (spot['x'] as num).toDouble();
      final double dy = (spot['y'] as num).toDouble();
      final String text = spot['number']?.toString() ?? '';
      final Color color = Color(spot['color'] ?? Colors.teal.value);

      final Offset spotCenter = Offset(
        cueCenter.dx + dx * ballRadius,
        cueCenter.dy + dy * ballRadius,
      );

      // Draw spot circle
      final Paint spotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(spotCenter, computedSpotRadius, spotPaint);

      final Paint spotBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(spotCenter, computedSpotRadius, spotBorder);

      // Contrast text color based on spot color brightness
      final Color textColor = color.computeLuminance() > 0.6
          ? Colors.black87
          : Colors.white;

      // Draw number inside spot
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: 8.5 * (spotSize / 25.0),
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
