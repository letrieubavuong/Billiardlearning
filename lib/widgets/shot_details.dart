import 'package:flutter/material.dart';
import 'dart:math' as math;

// Widget hiển thị độ dày cách chạm bi, Ép-phê và Ngọn cơ chân thực
class ImpactIndicator extends StatelessWidget {
  final double thickness;
  final Offset effet;
  final double cueAngle;
  final double size;
  final String? forceImagePath; // Đường dẫn hình ảnh lực tay

  const ImpactIndicator({
    super.key,
    required this.thickness,
    required this.effet,
    this.cueAngle = 0,
    this.size = 100,
    this.forceImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Kỹ thuật chạm & Cơ tay & Lực',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Nhìn trực diện: Chạm trái & Tầng bi
            CustomPaint(
              size: Size(size * 1.6, size),
              painter: ImpactPainter(thickness, effet),
            ),
            const SizedBox(width: 10),
            // 2. Nhìn từ cạnh: Độ cao cơ & Góc nghiêng
            CustomPaint(
              size: Size(size * 1, size),
              painter: CueElevationPainter(cueAngle, effet.dy),
            ),
            // 3. Hình ảnh lực tay (nếu có)
            if (forceImagePath != null) ...[
              const SizedBox(width: 15),
              Container(
                width: size * 0.85,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    forceImagePath!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class ImpactPainter extends CustomPainter {
  final double thickness;
  final Offset effet;
  ImpactPainter(this.thickness, this.effet);

  @override
  void paint(Canvas canvas, Size size) {
    double ballRadius = size.height / 2.8;
    double centerY = size.height / 2;
    double objCenterX = size.width / 3.5;

    // Tỉ lệ đầu cơ thực tế (11.5mm / 61.5mm ≈ 0.187 so với đường kính bi)
    double tipRadius = ballRadius * 0.187;

    // 1. Bi mục tiêu (Đỏ)
    canvas.drawCircle(
      Offset(objCenterX, centerY),
      ballRadius,
      Paint()..color = Colors.red,
    );

    // Vẽ 8 vạch chia dọc trên bi đỏ
    Paint linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 8; i++) {
      double x = (objCenterX - ballRadius) + (ballRadius * 2 * i / 8);
      double dx = (x - objCenterX).abs();
      if (dx < ballRadius) {
        double dy = math.sqrt(ballRadius * ballRadius - dx * dx);
        canvas.drawLine(
          Offset(x, centerY - dy),
          Offset(x, centerY + dy),
          linePaint,
        );
      }
    }

    // 2. Bi chủ (Trắng)
    double cueOffsetX = (1.0 - thickness) * (ballRadius * 2);
    Offset cueCenter = Offset(objCenterX + cueOffsetX, centerY);

    canvas.drawCircle(
      cueCenter + const Offset(2, 2),
      ballRadius,
      Paint()..color = Colors.black26,
    );
    canvas.drawCircle(cueCenter, ballRadius, Paint()..color = Colors.white);

    // Vẽ lưới Tầng bi (Ngang) và Độ dày (Dọc) trên bi chủ
    Paint gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 8; i++) {
      double x = (cueCenter.dx - ballRadius) + (ballRadius * 2 * i / 8);
      double dx = (x - cueCenter.dx).abs();
      if (dx < ballRadius) {
        double dy = math.sqrt(ballRadius * ballRadius - dx * dx);
        canvas.drawLine(
          Offset(x, cueCenter.dy - dy),
          Offset(x, cueCenter.dy + dy),
          gridPaint,
        );
      }
      double y = (cueCenter.dy - ballRadius) + (ballRadius * 2 * i / 8);
      double dy = (y - cueCenter.dy).abs();
      if (dy < ballRadius) {
        double dx = math.sqrt(ballRadius * ballRadius - dy * dy);
        canvas.drawLine(
          Offset(cueCenter.dx - dx, y),
          Offset(cueCenter.dx + dx, y),
          gridPaint,
        );
      }
    }

    canvas.drawLine(
      Offset(cueCenter.dx - 4, cueCenter.dy),
      Offset(cueCenter.dx + 4, cueCenter.dy),
      Paint()..color = Colors.red.withOpacity(0.5),
    );
    canvas.drawLine(
      Offset(cueCenter.dx, cueCenter.dy - 4),
      Offset(cueCenter.dx, cueCenter.dy + 4),
      Paint()..color = Colors.red.withOpacity(0.5),
    );

    // 3. Điểm ép phê (Kích thước thực tế)
    Offset effetPos = Offset(
      cueCenter.dx + (effet.dx * ballRadius * 0.85),
      cueCenter.dy + (effet.dy * ballRadius * 0.85),
    );
    canvas.drawCircle(effetPos, tipRadius, Paint()..color = Colors.red);
    canvas.drawCircle(
      effetPos,
      tipRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Hiển thị nhãn độ dày
    int parts = (thickness * 8).round();
    TextPainter tp = TextPainter(
      text: TextSpan(
        text: '$parts/8',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(objCenterX - tp.width / 2, size.height - tp.height),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CueElevationPainter extends CustomPainter {
  final double angle;
  final double yEffet;
  CueElevationPainter(this.angle, this.yEffet);

  @override
  void paint(Canvas canvas, Size size) {
    double ballRadius = size.width / 3;
    Offset ballCenter = Offset(size.width / 2, size.height - ballRadius - 15);

    // Tỉ lệ đầu cơ thực tế (11.5mm / 61.5mm ≈ 0.187)
    double tipRadius = ballRadius * 0.15;

    // 1. Vẽ bi & Mặt bàn
    canvas.drawCircle(ballCenter, ballRadius, Paint()..color = Colors.white);
    canvas.drawLine(
      Offset(0, size.height - 15),
      Offset(size.width, size.height - 15),
      Paint()..color = Colors.white54,
    );

    // 2. Tính toán điểm chạm cơ dựa trên Tầng bi (yEffet)
    double hitY = ballCenter.dy + (yEffet * ballRadius * 0.85);
    double dy = (hitY - ballCenter.dy).abs();
    double dx = math.sqrt(math.max(0, ballRadius * ballRadius - dy * dy));
    Offset tipPos = Offset(ballCenter.dx - dx, hitY);

    // 3. Vẽ gậy bida chân thực (Shaft + Ferrule + Tip)
    double rad = angle * math.pi / 180;
    double stickLen = 45.0;
    Offset ferruleEnd = Offset(
      tipPos.dx - 8 * math.cos(rad),
      tipPos.dy - 8 * math.sin(rad),
    );
    Offset shaftEnd = Offset(
      tipPos.dx - stickLen * math.cos(rad),
      tipPos.dy - stickLen * math.sin(rad),
    );

    // Thân gỗ (Tapered)
    Path shaftPath = Path();
    double tFront = tipRadius; // Phíp cơ to bằng đầu tẩy
    double tBack = tipRadius * 1.2; // Thân gỗ to dần về phía sau

    shaftPath.moveTo(
      ferruleEnd.dx + tFront * math.sin(rad),
      ferruleEnd.dy - tFront * math.cos(rad),
    );
    shaftPath.lineTo(
      shaftEnd.dx + tBack * math.sin(rad),
      shaftEnd.dy - tBack * math.cos(rad),
    );
    shaftPath.lineTo(
      shaftEnd.dx - tBack * math.sin(rad),
      shaftEnd.dy + tBack * math.cos(rad),
    );
    shaftPath.lineTo(
      ferruleEnd.dx - tFront * math.sin(rad),
      ferruleEnd.dy + tFront * math.cos(rad),
    );
    shaftPath.close();
    canvas.drawPath(shaftPath, Paint()..color = const Color(0xFFD7CCC8));

    // Phíp (Ferrule)
    canvas.drawLine(
      ferruleEnd,
      tipPos,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = tFront * 2,
    );

    // Đầu tẩy (Tip)
    canvas.drawArc(
      Rect.fromCircle(center: tipPos, radius: tipRadius),
      rad + math.pi / 2,
      math.pi,
      true,
      Paint()..color = Colors.blue.shade700,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
