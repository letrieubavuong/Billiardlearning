import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class EffetDiagramBuilderPage extends StatefulWidget {
  final String? initialData;
  const EffetDiagramBuilderPage({super.key, this.initialData});

  @override
  State<EffetDiagramBuilderPage> createState() =>
      _EffetDiagramBuilderPageState();
}

class _EffetDiagramBuilderPageState extends State<EffetDiagramBuilderPage> {
  List<Map<String, dynamic>> _spots = [];
  int? _selectedSpotIndex;
  Offset? _dragPosition;

  bool _showHitBall = false;
  int _hitThickness = 6;
  String _hitSide = 'right';
  double _spotSize = 25.0;

  final List<Color> _presetColors = [
    const Color(0xFF4DD0E1), // Cyan (like original image)
    Colors.orange,
    Colors.redAccent,
    Colors.yellow,
    Colors.white,
    Colors.blue, // Blue color added
    Colors.greenAccent,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      try {
        final decoded = jsonDecode(widget.initialData!);
        if (decoded is Map) {
          if (decoded.containsKey('spots')) {
            _spots = List<Map<String, dynamic>>.from(
              (decoded['spots'] as List).map(
                (e) => Map<String, dynamic>.from(e),
              ),
            );
          }
          _showHitBall = decoded['showHitBall'] ?? false;
          _hitThickness = decoded['hitThickness'] ?? 6;
          _hitSide = decoded['hitSide'] ?? 'right';
          _spotSize = (decoded['spotSize'] as num?)?.toDouble() ?? 25.0;
        }
      } catch (_) {}
    }
  }

  void _addSpot(Offset relativePos) {
    // Determine next default number
    int nextNum = 1;
    final List<int> existingNums = _spots
        .map((s) => int.tryParse(s['number']?.toString() ?? '') ?? 0)
        .where((n) => n > 0)
        .toList();
    if (existingNums.isNotEmpty) {
      nextNum = existingNums.reduce(math.max) + 1;
    }

    setState(() {
      _spots.add({
        'x': relativePos.dx,
        'y': relativePos.dy,
        'number': '$nextNum',
        'color': _presetColors.first.value,
      });
      _selectedSpotIndex = _spots.length - 1;
    });
  }

  void _deleteSelectedSpot() {
    if (_selectedSpotIndex == null) return;
    setState(() {
      _spots.removeAt(_selectedSpotIndex!);
      _selectedSpotIndex = null;
    });
  }

  void _updateSelectedSpotColor(Color color) {
    if (_selectedSpotIndex == null) return;
    setState(() {
      _spots[_selectedSpotIndex!]['color'] = color.value;
    });
  }

  void _updateSelectedSpotNumber(String number) {
    if (_selectedSpotIndex == null) return;
    setState(() {
      _spots[_selectedSpotIndex!]['number'] = number;
    });
  }

  void _showCoordinateInputDialog() {
    if (_selectedSpotIndex == null) return;
    final spot = _spots[_selectedSpotIndex!];

    double x = (spot['x'] as num).toDouble();
    double y = (spot['y'] as num).toDouble();

    // Initial values
    double r = math.sqrt(x * x + y * y).clamp(0.0, 1.0);
    double angleDeg = math.atan2(-y, x) * 180 / math.pi;
    if (angleDeg < 0) angleDeg += 360;

    final xController = TextEditingController(text: x.toStringAsFixed(2));
    final yController = TextEditingController(text: y.toStringAsFixed(2));
    final rController = TextEditingController(text: r.toStringAsFixed(2));
    final aController = TextEditingController(
      text: angleDeg.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Tùy chỉnh tọa độ Ép-phê'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Điều chỉnh theo hệ Descartes (X, Y) hoặc hệ Cực (Góc, Bán kính) để thay đổi điểm ép-phê:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Hệ Descartes (Tâm là 0, 0)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.cyanAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: xController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'X (Ngang: -1 đến 1)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final double newX = double.tryParse(val) ?? 0.0;
                          final double currentY =
                              double.tryParse(yController.text) ?? 0.0;
                          double newR = math.sqrt(
                            newX * newX + currentY * currentY,
                          );
                          if (newR > 1.0) {
                            newR = 1.0;
                          }
                          double newAngle =
                              math.atan2(-currentY, newX) * 180 / math.pi;
                          if (newAngle < 0) newAngle += 360;

                          rController.text = newR.toStringAsFixed(2);
                          aController.text = newAngle.toStringAsFixed(0);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: yController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Y (Dọc: -1 đến 1)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final double currentX =
                              double.tryParse(xController.text) ?? 0.0;
                          final double newY = double.tryParse(val) ?? 0.0;
                          double newR = math.sqrt(
                            currentX * currentX + newY * newY,
                          );
                          if (newR > 1.0) {
                            newR = 1.0;
                          }
                          double newAngle =
                              math.atan2(-newY, currentX) * 180 / math.pi;
                          if (newAngle < 0) newAngle += 360;

                          rController.text = newR.toStringAsFixed(2);
                          aController.text = newAngle.toStringAsFixed(0);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Hệ Cực (Bán kính & Góc xoay)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: aController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Góc (0° - 360°)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final double angle = double.tryParse(val) ?? 0.0;
                          final double currentR =
                              double.tryParse(rController.text) ?? 0.0;
                          final double rad = angle * math.pi / 180;
                          final double newX = currentR * math.cos(rad);
                          final double newY = -currentR * math.sin(rad);

                          xController.text = newX.toStringAsFixed(2);
                          yController.text = newY.toStringAsFixed(2);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Bán kính (0.0 - 1.0)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final double newR = (double.tryParse(val) ?? 0.0)
                              .clamp(0.0, 1.0);
                          final double angle =
                              double.tryParse(aController.text) ?? 0.0;
                          final double rad = angle * math.pi / 180;
                          final double newX = newR * math.cos(rad);
                          final double newY = -newR * math.sin(rad);

                          xController.text = newX.toStringAsFixed(2);
                          yController.text = newY.toStringAsFixed(2);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                final finalX = double.tryParse(xController.text) ?? 0.0;
                final finalY = double.tryParse(yController.text) ?? 0.0;

                final dist = math.sqrt(finalX * finalX + finalY * finalY);
                double dx = finalX;
                double dy = finalY;
                if (dist > 1.0) {
                  dx /= dist;
                  dy /= dist;
                }

                setState(() {
                  _spots[_selectedSpotIndex!]['x'] = dx.clamp(-1.0, 1.0);
                  _spots[_selectedSpotIndex!]['y'] = dy.clamp(-1.0, 1.0);
                });
                Navigator.pop(context);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biểu đồ Ép-phê'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: () {
              final String result = jsonEncode({
                'spots': _spots,
                'showHitBall': _showHitBall,
                'hitThickness': _hitThickness,
                'hitSide': _hitSide,
                'spotSize': _spotSize,
              });
              Navigator.pop(context, result);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          const Text(
            'Biểu đồ Ép-phê & Chạm trái',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.cyanAccent,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Chạm vào quả bi trắng để đặt điểm ép-phê.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 15),
          // Bàn vẽ quả bi
          Expanded(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 15,
                      offset: Offset(2, 6),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double sizeWidth = constraints.maxWidth;
                    final double sizeHeight = constraints.maxHeight;
                    final double radius = sizeHeight / 2;
                    final Offset canvasCenter = Offset(
                      sizeWidth / 2,
                      sizeHeight / 2,
                    );

                    final double ballRadius = _showHitBall
                        ? (sizeHeight / 2.8)
                        : radius;

                    // Calculate centers
                    Offset cueCenter = canvasCenter;
                    if (_showHitBall) {
                      final double centerDist =
                          2 * ballRadius * (1 - _hitThickness / 12);
                      final double halfDist = centerDist / 2;
                      if (_hitSide == 'right') {
                        cueCenter = Offset(
                          canvasCenter.dx + halfDist,
                          canvasCenter.dy,
                        );
                      } else {
                        cueCenter = Offset(
                          canvasCenter.dx - halfDist,
                          canvasCenter.dy,
                        );
                      }
                    }

                    return GestureDetector(
                      onTapUp: (details) {
                        final Offset localPos = details.localPosition;
                        final double dx =
                            (localPos.dx - cueCenter.dx) / ballRadius;
                        final double dy =
                            (localPos.dy - cueCenter.dy) / ballRadius;

                        // Check if we hit an existing spot
                        int? hitIndex;
                        for (int i = 0; i < _spots.length; i++) {
                          final double sx = (_spots[i]['x'] as num).toDouble();
                          final double sy = (_spots[i]['y'] as num).toDouble();
                          final double dist = math.sqrt(
                            (sx - dx) * (sx - dx) + (sy - dy) * (sy - dy),
                          );
                          if (dist < 0.25) {
                            hitIndex = i;
                            break;
                          }
                        }

                        if (hitIndex != null) {
                          setState(() {
                            _selectedSpotIndex = hitIndex;
                          });
                        } else {
                          // Tap inside the unit circle limits of the cue ball
                          final double dist = math.sqrt(dx * dx + dy * dy);
                          if (dist <= 1.0) {
                            _addSpot(Offset(dx, dy));
                          }
                        }
                      },
                      onPanStart: (details) {
                        final RenderBox renderBox =
                            context.findRenderObject() as RenderBox;
                        final Offset localPos = renderBox.globalToLocal(
                          details.globalPosition,
                        );
                        final double dx =
                            (localPos.dx - cueCenter.dx) / ballRadius;
                        final double dy =
                            (localPos.dy - cueCenter.dy) / ballRadius;

                        int? hitIndex;
                        for (int i = 0; i < _spots.length; i++) {
                          final double sx = (_spots[i]['x'] as num).toDouble();
                          final double sy = (_spots[i]['y'] as num).toDouble();
                          final double dist = math.sqrt(
                            (sx - dx) * (sx - dx) + (sy - dy) * (sy - dy),
                          );
                          if (dist < 0.25) {
                            hitIndex = i;
                            break;
                          }
                        }
                        if (hitIndex != null) {
                          setState(() {
                            _selectedSpotIndex = hitIndex;
                            _dragPosition = localPos;
                          });
                        }
                      },
                      onPanUpdate: (details) {
                        if (_selectedSpotIndex == null) return;
                        final RenderBox renderBox =
                            context.findRenderObject() as RenderBox;
                        final Offset localPos = renderBox.globalToLocal(
                          details.globalPosition,
                        );

                        double dx = (localPos.dx - cueCenter.dx) / ballRadius;
                        double dy = (localPos.dy - cueCenter.dy) / ballRadius;

                        final double dist = math.sqrt(dx * dx + dy * dy);
                        if (dist > 1.0) {
                          dx /= dist;
                          dy /= dist;
                        }

                        setState(() {
                          _spots[_selectedSpotIndex!]['x'] = dx;
                          _spots[_selectedSpotIndex!]['y'] = dy;
                          _dragPosition = localPos;
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _dragPosition = null;
                        });
                      },
                      onPanCancel: () {
                        setState(() {
                          _dragPosition = null;
                        });
                      },
                      child: Stack(
                        children: [
                          // Ball base (White cue ball)
                          Positioned(
                            left: cueCenter.dx - ballRadius,
                            top: cueCenter.dy - ballRadius,
                            child: Container(
                              width: ballRadius * 2,
                              height: ballRadius * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF9F9F9),
                                border: Border.all(
                                  color: Colors.black87,
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),
                          // Background grid (rings, clock lines, vertical/horizontal division, target ball)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CueBallBackgroundPainter(
                                showHitBall: _showHitBall,
                                hitThickness: _hitThickness,
                                hitSide: _hitSide,
                              ),
                            ),
                          ),
                          // Crosshairs (for cue ball center)
                          Positioned(
                            left: cueCenter.dx - ballRadius,
                            top: cueCenter.dy - 0.6,
                            child: Container(
                              width: ballRadius * 2,
                              height: 1.2,
                              color: Colors.black38,
                            ),
                          ),
                          Positioned(
                            left: cueCenter.dx - 0.6,
                            top: cueCenter.dy - ballRadius,
                            child: Container(
                              width: 1.2,
                              height: ballRadius * 2,
                              color: Colors.black38,
                            ),
                          ),

                          // Placed spots
                          ..._spots.asMap().entries.map((entry) {
                            final int idx = entry.key;
                            final map = entry.value;
                            final double x = (map['x'] as num).toDouble();
                            final double y = (map['y'] as num).toDouble();
                            final String number =
                                map['number']?.toString() ?? '';
                            final Color color = Color(
                              map['color'] ?? _presetColors.first.value,
                            );
                            final bool isSelected = _selectedSpotIndex == idx;

                            final double px = cueCenter.dx + x * ballRadius;
                            final double py = cueCenter.dy + y * ballRadius;

                            final Color textColor =
                                color.computeLuminance() > 0.6
                                ? Colors.black87
                                : Colors.white;

                            final double halfSpot = _spotSize / 2;
                            return Positioned(
                              left: px - halfSpot,
                              top: py - halfSpot,
                              child: Container(
                                width: _spotSize,
                                height: _spotSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.orangeAccent
                                        : Colors.white,
                                    width: isSelected ? 2.5 : 1.2,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      const BoxShadow(
                                        color: Colors.orangeAccent,
                                        blurRadius: 6,
                                      )
                                    else
                                      const BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 3,
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    number,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: _spotSize * 0.4,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          if (_dragPosition != null &&
                              _selectedSpotIndex != null)
                            () {
                              final double left = (_dragPosition!.dx - 50)
                                  .clamp(0.0, sizeWidth - 100.0);
                              final double top = (_dragPosition!.dy - 110)
                                  .clamp(0.0, sizeHeight - 100.0);
                              final double centerX = left + 50.0;
                              final double centerY = top + 50.0;
                              final Offset dynamicFocalPointOffset = Offset(
                                _dragPosition!.dx - centerX,
                                _dragPosition!.dy - centerY,
                              );

                              return Positioned(
                                left: left,
                                top: top,
                                child: RawMagnifier(
                                  decoration: const MagnifierDecoration(
                                    shape: CircleBorder(
                                      side: BorderSide(
                                        color: Colors.orangeAccent,
                                        width: 2,
                                      ),
                                    ),
                                    shadows: [
                                      BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  size: const Size(100, 100),
                                  magnificationScale: 2.0,
                                  focalPointOffset: dynamicFocalPointOffset,
                                ),
                              );
                            }(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Bảng điều khiển
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- GLOBAL SETTINGS (CHẠM TRÁI) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bật phần chạm trái:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      Switch(
                        value: _showHitBall,
                        activeColor: Colors.cyanAccent,
                        onChanged: (val) {
                          setState(() {
                            _showHitBall = val;
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Cỡ chấm ép-phê:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _spotSize,
                          min: 15.0,
                          max: 35.0,
                          divisions: 20,
                          activeColor: Colors.cyanAccent,
                          inactiveColor: Colors.grey[700],
                          onChanged: (val) {
                            setState(() {
                              _spotSize = val;
                            });
                          },
                        ),
                      ),
                      Text(
                        _spotSize.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (_showHitBall) ...[
                    Row(
                      children: [
                        Text(
                          'Độ dày chạm: ${_hitThickness}/12',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _hitThickness.toDouble(),
                            min: 0,
                            max: 12,
                            divisions: 12,
                            activeColor: Colors.redAccent,
                            inactiveColor: Colors.grey[700],
                            onChanged: (val) {
                              setState(() {
                                _hitThickness = val.round();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hướng chạm (Bi chủ lệch về):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SegmentedButton<String>(
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: Colors.cyan[700],
                            selectedForegroundColor: Colors.white,
                          ),
                          segments: const [
                            ButtonSegment(value: 'left', label: Text('Trái')),
                            ButtonSegment(value: 'right', label: Text('Phải')),
                          ],
                          selected: {_hitSide},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _hitSide = newSelection.first;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.grey, height: 20),
                  ],

                  // --- SPOT-SPECIFIC SETTINGS ---
                  if (_selectedSpotIndex == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Chạm vào điểm hoặc chạm lên quả bi để chọn/thêm điểm.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        const Text(
                          'Số ép-phê:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.text,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              hintText: 'Nhập số/chữ hiển thị...',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            controller:
                                TextEditingController(
                                    text:
                                        _spots[_selectedSpotIndex!]['number']
                                            ?.toString() ??
                                        '',
                                  )
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset:
                                          (_spots[_selectedSpotIndex!]['number']
                                                      ?.toString() ??
                                                  '')
                                              .length,
                                    ),
                                  ),
                            onChanged: _updateSelectedSpotNumber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _showCoordinateInputDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          icon: const Icon(Icons.location_on, size: 14),
                          label: const Text(
                            'Tọa độ',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _deleteSelectedSpot,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 14),
                          label: const Text(
                            'Xoá',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Màu sắc:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _presetColors.map((color) {
                              final isSelected =
                                  _spots[_selectedSpotIndex!]['color'] ==
                                  color.value;
                              return GestureDetector(
                                onTap: () => _updateSelectedSpotColor(color),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.orangeAccent
                                          : Colors.transparent,
                                      width: isSelected ? 2.5 : 1.0,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.black,
                                          size: 14,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CueBallBackgroundPainter extends CustomPainter {
  final bool showHitBall;
  final int hitThickness;
  final String hitSide;

  CueBallBackgroundPainter({
    required this.showHitBall,
    required this.hitThickness,
    required this.hitSide,
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

    // Concentric circles (4 layers)
    final Paint ringPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(cueCenter, ballRadius * (i / 4), ringPaint);
    }

    // Clock-hour division lines (every 30 degrees)
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
      if (i == 4) continue; // Skip center vertical line
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
      if (i == 4) continue; // Skip center horizontal line
      final double y = cueCenter.dy - ballRadius + (ballRadius * 2 * i) / 8;
      final double dy = (y - cueCenter.dy).abs();
      final double dx = math.sqrt(ballRadius * ballRadius - dy * dy);
      canvas.drawLine(
        Offset(cueCenter.dx - dx, y),
        Offset(cueCenter.dx + dx, y),
        divisionLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
