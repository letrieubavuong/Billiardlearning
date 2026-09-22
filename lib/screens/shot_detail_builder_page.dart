import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/shot_details.dart';

class ShotDetailBuilderPage extends StatefulWidget {
  final String? initialData;
  const ShotDetailBuilderPage({super.key, this.initialData});

  @override
  State<ShotDetailBuilderPage> createState() => _ShotDetailBuilderPageState();
}

class _ShotDetailBuilderPageState extends State<ShotDetailBuilderPage> {
  double thickness = 0.5; // 4/8
  Offset effet = const Offset(0.0, 0.0);
  int selectedForce = 2; // Mặc định Lực 2
  double cueAngle = 0.0; // Độ nghiêng cơ (0 - 90 độ)

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      try {
        final data = jsonDecode(widget.initialData!);
        thickness = (data['thickness'] ?? 0.5).toDouble();
        cueAngle = (data['cueAngle'] ?? 0.0).toDouble();
        if (data.containsKey('effet')) {
          effet = Offset(
            (data['effet'][0] as num).toDouble(),
            (data['effet'][1] as num).toDouble(),
          );
        }
        if (data.containsKey('forceImage')) {
          final String path = data['forceImage'].toString();
          if (path.contains('Luc 1')) selectedForce = 1;
          if (path.contains('Luc 2')) selectedForce = 2;
          if (path.contains('Luc 3')) selectedForce = 3;
          if (path.contains('Luc 4')) selectedForce = 4;
        }
      } catch (e) {
        // Bỏ qua nếu lỗi
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết cú đánh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.orangeAccent),
            onPressed: () {
              final data = {
                "thickness": thickness,
                "effet": [effet.dx, effet.dy],
                "forceImage": "assets/images/Luc $selectedForce.png",
                "cueAngle": cueAngle,
              };
              Navigator.pop(context, jsonEncode(data));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ImpactIndicator(
                thickness: thickness,
                effet: effet,
                size: 85,
                cueAngle: cueAngle,
                forceImagePath: "assets/images/Luc $selectedForce.png",
              ),
              const SizedBox(height: 30),
              const Text(
                'Độ dày (Trái bi)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: thickness,
                min: 0.0,
                max: 1.0,
                divisions: 8,
                label: '${(thickness * 8).round()}/8',
                onChanged: (val) => setState(() => thickness = val),
              ),
              const SizedBox(height: 20),
              const Text(
                'Độ nghiêng cơ (Độ)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: cueAngle,
                min: 0.0,
                max: 90.0,
                divisions: 90,
                label: '${cueAngle.round()}°',
                onChanged: (val) => setState(() => cueAngle = val),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lực tay (Độ mạnh cú đánh)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final int forceNum = index + 1;
                  final bool isSelected = selectedForce == forceNum;
                  return GestureDetector(
                    onTap: () => setState(() => selectedForce = forceNum),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.orangeAccent
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        'Lực $forceNum',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              const Text(
                'Ép-phê (Chạm để chọn)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onPanUpdate: (details) =>
                    _updateEffet(details.localPosition, 150),
                onTapDown: (details) =>
                    _updateEffet(details.localPosition, 150),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white10,
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Vòng tròn lưới đồng tâm (Snap grid)
                      ...List.generate(6, (index) {
                        final double radiusMultiplier = (index + 1) / 6.0;
                        final double diameter = 150 * radiusMultiplier;
                        return Center(
                          child: Container(
                            width: diameter,
                            height: diameter,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 0.5,
                              ),
                            ),
                          ),
                        );
                      }),
                      Center(
                        child: Container(
                          width: 150,
                          height: 1,
                          color: Colors.white24,
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 1,
                          height: 150,
                          color: Colors.white24,
                        ),
                      ),
                      Positioned(
                        left: 75 + (effet.dx * 75) - 14,
                        top: 75 + (effet.dy * 75) - 14,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withOpacity(0.95),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(1, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Kéo đầu cơ đỏ bắt lưới 1/12 quả bi hoặc chạm vào vòng tròn để chọn',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateEffet(Offset localPos, double size) {
    final double radius = size / 2;
    // Tọa độ chuẩn hóa từ -1.0 đến 1.0 tương ứng với bán kính quả bi (75px)
    final double dx = (localPos.dx - radius) / radius;
    final double dy = (localPos.dy - radius) / radius;

    // Bắt lưới (Snap) theo 1/12 quả bi (tương ứng với 1/6 bán kính quả bi)
    double snappedDx = (dx * 6).round() / 6;
    double snappedDy = (dy * 6).round() / 6;

    final double distance = math.sqrt(
      snappedDx * snappedDx + snappedDy * snappedDy,
    );
    if (distance > 1.0) {
      snappedDx /= distance;
      snappedDy /= distance;
      snappedDx = (snappedDx * 6).round() / 6;
      snappedDy = (snappedDy * 6).round() / 6;
    }

    setState(() {
      effet = Offset(snappedDx.clamp(-1.0, 1.0), snappedDy.clamp(-1.0, 1.0));
    });
  }
}
